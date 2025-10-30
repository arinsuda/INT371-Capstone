FROM cirrusci/flutter


ENV DEBIAN_FRONTEND=noninteractive


ENV LANG=en_US.UTF-8


ENV JAVA_HOME="/usr/lib/jvm/temurin-8-jdk-amd64"
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
ENV ANDROID_TOOLS_ROOT="/opt/android_sdk"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools:${ANDROID_TOOLS_ROOT}/tools/bin:/usr/bin:${PATH}"


RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    
    git \
    wget \
    curl \
    zip \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    
    build-essential \
    gcc \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    
    default-jdk-headless \
    
    lib32stdc++6 \
    libglu1-mesa \
    libstdc++6 \
    libgtk-3-dev \
    
    x11-xserver-utils \
    xauth \
    xvfb \
    
    nodejs \
    npm \
    ruby \
    ruby-dev \
    
    locales && \
    
    locale-gen en_US "en_US.UTF-8" && \
    dpkg-reconfigure locales && \
    
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main' | \
    tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-sdk && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | \
    gpg --dearmor -o /usr/share/keyrings/adoptium.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bullseye main" | \
    tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends temurin-8-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN mkdir -p "${ANDROID_TOOLS_ROOT}" ~/.android && \
    touch ~/.android/repositories.cfg && \
    wget --progress=dot:giga "${ANDROID_SDK_URL}" -O /tmp/android-sdk.zip && \
    unzip -q -d "${ANDROID_TOOLS_ROOT}" /tmp/android-sdk.zip && \
    rm /tmp/android-sdk.zip


RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" \
    "tools" \
    "build-tools;28.0.3" \
    "platforms;android-30" \
    "platform-tools" \
    "cmdline-tools;latest" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "patcher;v4" > /dev/null


RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" --licenses > /dev/null || true


ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64


WORKDIR /root


RUN flutter create . && \
    flutter build apk --release && \
    rm -rf /root/*


WORKDIR /app


CMD ["/bin/bash"]