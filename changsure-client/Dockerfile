FROM cirrusci/flutter

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set locale early
ENV LANG=en_US.UTF-8

# Set Java and Android environment variables
ENV JAVA_HOME="/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64"
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
ENV ANDROID_TOOLS_ROOT="/opt/android_sdk"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools:${ANDROID_TOOLS_ROOT}/tools/bin:/usr/bin:${PATH}"

# Install system dependencies in a single layer
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    # Basic tools
    git \
    wget \
    curl \
    zip \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    # Build tools
    build-essential \
    gcc \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    # Java
    default-jdk-headless \
    # System libraries
    lib32stdc++6 \
    libglu1-mesa \
    libstdc++6 \
    libgtk-3-dev \
    # Desktop support
    x11-xserver-utils \
    xauth \
    xvfb \
    # Node.js and Ruby
    nodejs \
    npm \
    ruby \
    ruby-dev \
    # Locales
    locales && \
    # Set up locale
    locale-gen en_US "en_US.UTF-8" && \
    dpkg-reconfigure locales && \
    # Clean up apt cache
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Google Chrome repository and install
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main' | \
    tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Google Cloud SDK repository and install
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

# Add AdoptOpenJDK 8 repository and install
RUN wget -q -O - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | \
    gpg --dearmor -o /usr/share/keyrings/adoptopenjdk.gpg && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/adoptopenjdk.gpg] https://adoptopenjdk.jfrog.io/adoptopenjdk/deb bullseye main' | \
    tee /etc/apt/sources.list.d/adoptopenjdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends adoptopenjdk-8-hotspot && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up Android SDK
RUN mkdir -p "${ANDROID_TOOLS_ROOT}" ~/.android && \
    touch ~/.android/repositories.cfg && \
    wget --progress=dot:giga "${ANDROID_SDK_URL}" -O /tmp/android-sdk.zip && \
    unzip -q -d "${ANDROID_TOOLS_ROOT}" /tmp/android-sdk.zip && \
    rm /tmp/android-sdk.zip

# Install Android SDK components
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" \
    "tools" \
    "build-tools;28.0.3" \
    "platforms;android-30" \
    "platform-tools" \
    "cmdline-tools;latest" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "patcher;v4" > /dev/null

# Accept Android licenses
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" --licenses > /dev/null || true

# Update JAVA_HOME for runtime (Java 11)
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Set working directory
WORKDIR /root

# Build a sample project to cache dependencies (optional, can be removed if not needed)
RUN flutter create . && \
    flutter build apk --release && \
    rm -rf /root/*

# Reset working directory for actual usage
WORKDIR /app

# Default command
CMD ["/bin/bash"]