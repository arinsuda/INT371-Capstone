FROM ghcr.io/cirruslabs/flutter:stable-android

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

ARG ANDROID_PLATFORM=android-34
ARG ANDROID_BUILD_TOOLS=34.0.0

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg apt-transport-https \
      zip unzip git locales \
      clang cmake ninja-build pkg-config libgtk-3-dev \
      x11-xserver-utils xauth xvfb; \
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen; \
    locale-gen; \
    install -m 0755 -d /usr/share/keyrings; \

    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      -o /usr/share/keyrings/google-linux-signing-key.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb stable main" \
      > /etc/apt/sources.list.d/google-chrome.list; \

    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      -o /usr/share/keyrings/google-cloud.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      google-chrome-stable google-cloud-sdk; \
    gcloud config set core/disable_usage_reporting true; \
    gcloud config set component_manager/disable_update_check true; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    yes "y" | sdkmanager --licenses > /dev/null; \
    yes "y" | sdkmanager \
      "platforms;${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "platform-tools" > /dev/null

WORKDIR /workspace