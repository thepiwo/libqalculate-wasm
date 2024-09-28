FROM --platform=linux/amd64 ubuntu:latest AS builder

ENV GMP_VERSION=6.3.0 \
	MPFR_VERSION=4.2.1 \
	LIBXML2_VERSION=2.9.12 \
	EM_VERSION=3.1.67

SHELL ["/bin/bash", "-c"]

RUN apt update \
	&& apt install -y build-essential lzip binutils autoconf intltool libtool automake lbzip2 lzip git xz-utils wget pkg-config python3 \
	&& mkdir -p ~/opt/src

RUN	cd ~ \
	&& git clone https://github.com/juj/emsdk.git \
	&& cd emsdk \
	&& ./emsdk install ${EM_VERSION} \
	&& ./emsdk activate ${EM_VERSION}

RUN cd ~/opt/src \
	&& source ~/emsdk/emsdk_env.sh \
	&& wget https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.lz \
	&& tar xf gmp-${GMP_VERSION}.tar.lz \
	&& cd gmp-${GMP_VERSION} \
	&& emconfigure ./configure --disable-assembly --host none --enable-cxx --prefix=${HOME}/opt \
	&& make \
	&& make install

RUN cd ~/opt/src \
	&& source ~/emsdk/emsdk_env.sh \
	&& wget https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz \
	&& tar xf mpfr-${MPFR_VERSION}.tar.xz \
	&& cd mpfr-${MPFR_VERSION} \
	&& emconfigure ./configure --prefix=${HOME}/opt --with-gmp=${HOME}/opt \
	&& make \
	&& make install

RUN cd ~/opt/src \
	&& source ~/emsdk/emsdk_env.sh \
	&& wget http://xmlsoft.org/download/libxml2-${LIBXML2_VERSION}.tar.gz \
	&& tar xf libxml2-${LIBXML2_VERSION}.tar.gz \
	&& cd libxml2-${LIBXML2_VERSION} \
	&& emconfigure ./configure --prefix=${HOME}/opt --disable-shared \
	&& make \
	&& make install \
	&& ln -s ${HOME}/opt/include/libxml2/libxml ${HOME}/opt/include/libxml

RUN cd ~/opt/src \
	&& source ~/emsdk/emsdk_env.sh \
	&& git clone https://github.com/Qalculate/libqalculate.git \
	&& cd libqalculate \
	&& export NOCONFIGURE=1 NO_AUTOMAKE=1 \
	&& ./autogen.sh \
	&& export LIBXML_CFLAGS="-I${HOME}/opt/include" LIBXML_LIBS="-L${HOME}/opt/lib -lxml2" \
	&& export CFLAGS="-I${HOME}/opt/include" LDFLAGS="-L${HOME}/opt/lib" \
	&& emconfigure ./configure --prefix=${HOME}/opt --without-libcurl --without-icu --enable-compiled-definitions --disable-nls --disable-shared --with-gnuplot-call=byo \
	&& cd data \
	&& make \
	&& cd ../libqalculate \
	&& make \
	&& make install

FROM --platform=linux/amd64 ubuntu:latest

COPY --from=builder /root/opt/include /usr/local/include
COPY --from=builder /root/opt/lib /usr/local/lib
COPY --from=builder /root/emsdk /root/emsdk

RUN apt update \
	&& apt install -y default-jre-headless python3 \
	&& rm -rf /var/lib/apt/lists/*