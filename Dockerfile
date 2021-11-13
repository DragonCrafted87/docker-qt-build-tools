FROM mcr.microsoft.com/windows/servercore:20H2 AS llvmtools
# https://hub.docker.com/_/microsoft-windows-servercore

ENV SCOOP "C:\scoop"
ENV SCOOP_HOME "C:\scoop\apps\scoop\current"

USER ContainerAdministrator
RUN setx /M PATH "%PATH%;C:\scoop\apps\python\current\Scripts"
USER ContainerUser

RUN powershell -NoLogo -Command "Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')"
RUN scoop install aria2 && \
    scoop install \
    cmake \
    git \
    make \
    ninja \
    perl \
    python \
    && \
    scoop bucket add dorado https://github.com/chawyehsu/dorado && \
    scoop install winlibs-mingw-llvm-ucrt  && \
    scoop uninstall aria2 && \
    scoop cache rm *

ENV LLVM_INSTALL_DIR="C:\scoop\apps\winlibs-mingw-llvm-ucrt\current"

FROM llvmtools AS qt_6_2_1_source
RUN git clone git://code.qt.io/qt/qt5.git qt && \
    cd qt && \
    git checkout v6.2.1 && \
    perl init-repository --module-subset=essential,addon,-qtwebengine,-qtsensors,-qtserialbus,-qtserialport

FROM qt_6_2_1_source AS qt_6_2_1_debug
RUN powershell -NoLogo -Command " \
    mkdir qt-build/debug; \
    cd qt-build/debug; \
    ..\..\qt\configure.bat -debug -shared -c++std c++14 -nomake examples -nomake tests -nomake tools; \
    cmake --build . --parallel 8; \
    cmake --install . \
    "

RUN powershell -NoLogo -Command " \
    mkdir qt-build/release; \
    cd qt-build/release; \
    ..\..\qt\configure.bat -release -static -optimize-size -c++std c++14 -nomake examples -nomake tests -nomake tools; \
    cmake --build . --parallel 8; \
    cmake --install . \
    "

RUN powershell -NoLogo -Command "$Env:Path"

ENTRYPOINT powershell.exe
