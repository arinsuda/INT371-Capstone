FROM cirrusci/flutter:stable

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set locale early
ENV LANG=en_US.UTF-8

# Set Android environment variables (ใช้ชื่อมาตรฐาน)
ENV ANDROID_HOME="/opt/android-sdk"
ENV ANDROID_SDK_ROOT="${ANDROID_HOME}"
ENV ANDROID_CMDLINE_TOOLS_VERSION="11076708"
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/33.0.2:/usr/bin:${PATH}"

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
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-sdk && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install OpenJDK (ใช้จาก Debian repository ตรงไม่มีปัญหา)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jdk \
    openjdk-17-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Java 11 as default (Flutter ใช้ได้ดีกับ Java 11)
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

# Set up Android SDK with modern command line tools
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" && \
    mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    cd "${ANDROID_HOME}/cmdline-tools" && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    unzip -q commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    rm commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    mv cmdline-tools latest

# Accept all Android SDK licenses first
RUN yes | sdkmanager --licenses || true

# Install Android SDK components (เฉพาะที่จำเป็นและมีอยู่จริง)
RUN sdkmanager --install \
    "platform-tools" \
    "platforms;android-33" \
    "platforms;android-34" \
    "build-tools;33.0.2" \
    "build-tools;34.0.0" \
    "cmdline-tools;latest" && \
    sdkmanager --update

# Verify installations
RUN sdkmanager --list_installed

# Set working directory
WORKDIR /app

# Verify Flutter installation
RUN flutter doctor -v

# Default command
CMD ["/bin/bash"]