# Flutter + Android (จาก Docker Hub)
FROM cirrusci/flutter:latest

# ----- Environment -----
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

# ----- System deps + Dev tools + Chrome + gcloud (no apt-key) -----
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
    # Google Chrome keyring + repo
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      -o /usr/share/keyrings/google-linux-signing-key.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb stable main" \
      > /etc/apt/sources.list.d/google-chrome.list; \
    # Google Cloud SDK keyring + repo
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

# ----- (ตัวเลือก) ติดตั้ง Android components เพิ่ม หากต้องการเวอร์ชันเฉพาะ -----
# NOTE: ภาพ cirrusci/flutter มักมี SDK แล้ว แต่ถ้าต้องการเจาะจง ให้ uncomment 4 บรรทัดด้านล่าง
# ARG ANDROID_PLATFORM=android-34
# ARG ANDROID_BUILD_TOOLS=34.0.0
# RUN yes "y" | sdkmanager --licenses > /dev/null
# RUN yes "y" | sdkmanager "platforms;${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" "platform-tools" > /dev/null

# ----- Working dir -----
WORKDIR /workspace

# คุณสามารถ COPY โค้ดเข้ามาและ build ใน image นี้ได้ หรือให้ pipeline run คำสั่งด้านนอกก็ได้
# ตัวอย่าง (optional):
# COPY . .
# RUN flutter pub get && flutter build apk --release