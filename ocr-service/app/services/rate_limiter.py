import asyncio
import time
from collections import deque, defaultdict

from app.core.exceptions import RateLimitExceeded  


class SlidingWindowRateLimiter:

    def __init__(self, limit: int = 10, window: int = 60, cleanup_every: int = 500) -> None:
        self._limit = limit
        self._window = window
        self._cleanup_every = cleanup_every

        
        self._windows: dict[str, deque] = defaultdict(deque)
        
        self._locks: dict[str, asyncio.Lock] = defaultdict(asyncio.Lock)
        
        self._registry_lock = asyncio.Lock()
        self._total_requests = 0

    async def check(self, ip: str) -> None:
        async with self._registry_lock:
            lock = self._locks[ip]
            window = self._windows[ip]
            self._total_requests += 1
            should_cleanup = (self._total_requests % self._cleanup_every) == 0

        async with lock:
            now = time.monotonic()
            cutoff = now - self._window

            
            while window and window[0] < cutoff:
                window.popleft()

            if len(window) >= self._limit:
                
                retry_after = round(window[0] - cutoff, 2)
                raise RateLimitExceeded(self._limit, self._window, retry_after)

            window.append(now)

        if should_cleanup:
            await self._evict_stale_ips()

    async def _evict_stale_ips(self) -> None:
        cutoff = time.monotonic() - self._window
        async with self._registry_lock:
            stale = [
                ip for ip, dq in self._windows.items()
                if not dq or dq[-1] < cutoff
            ]
            for ip in stale:
                del self._windows[ip]
                del self._locks[ip]

    @property
    def limit(self) -> int:
        return self._limit

    @property
    def window(self) -> int:
        return self._window



rate_limiter = SlidingWindowRateLimiter(limit=10, window=60)