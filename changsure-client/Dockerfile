FROM cirrusci/flutter:stable

ENV DEBIAN_FRONTEND=noninteractive

ENV LANG=en_US.UTF-8

ENV ANDROID_HOME="/opt/android-sdk"
ENV ANDROID_SDK_ROOT="${ANDROID_HOME}"
ENV ANDROID_CMDLINE_TOOLS_VERSION="11076708"
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/33.0.2:/usr/bin:${PATH}"

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

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jdk \
    openjdk-17-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" && \
    mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    cd "${ANDROID_HOME}/cmdline-tools" && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    unzip -q commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    rm commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    mv cmdline-tools latest

RUN yes | sdkmanager --licenses || true

RUN sdkmanager --install \
    "platform-tools" \
    "platforms;android-33" \
    "platforms;android-34" \
    "build-tools;33.0.2" \
    "build-tools;34.0.0" \
    "cmdline-tools;latest" && \
    sdkmanager --update

RUN sdkmanager --list_installed

WORKDIR /app

RUN flutter doctor -v

CMD ["/bin/bash"]