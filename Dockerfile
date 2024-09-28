FROM --platform=linux/amd64 ubuntu:latest AS builder

ENV GMP_VERSION=6.3.0 \
	MPFR_VERSION=4.2.1 \
	LIBXML2_VERSION=2.9.12 \
	EM_VERSION=3.1.67 \
	EM_NODE_VERSION=18.20.3_64bit

ENV EMSDK /emsdk

RUN apt update \
	&& apt install -y build-essential lzip binutils autoconf intltool libtool automake lbzip2 lzip git xz-utils wget pkg-config python3-minimal \
	&& mkdir -p ~/opt/src

RUN	cd / \
	&& git clone https://github.com/juj/emsdk.git \
	&& cd ${EMSDK} \
	&& ./emsdk install ${EM_VERSION} \
	&& ./emsdk activate ${EM_VERSION} \
	&& . ./emsdk_env.sh \
	# Remove debugging symbols from embedded node (extra 7MB)
	&& strip -s `which node` \
	# Tests consume ~80MB disc space
	&& rm -fr ${EMSDK}/upstream/emscripten/tests \
	# strip out symbols from clang (~extra 50MB disc space)
	&& find ${EMSDK}/upstream/bin -type f -exec strip -s {} + || true

ENV PATH="/emsdk:/emsdk/upstream/emscripten:/emsdk/node/${EM_NODE_VERSION}/bin:${PATH}"

RUN cd ~/opt/src \
	&& wget https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.lz \
	&& tar xf gmp-${GMP_VERSION}.tar.lz \
	&& cd gmp-${GMP_VERSION} \
	&& emconfigure ./configure --disable-assembly --host none --enable-cxx --prefix=/opt \
	&& make \
	&& make install

RUN cd ~/opt/src \
	&& wget https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz \
	&& tar xf mpfr-${MPFR_VERSION}.tar.xz \
	&& cd mpfr-${MPFR_VERSION} \
	&& emconfigure ./configure --prefix=/opt --with-gmp=/opt \
	&& make \
	&& make install

RUN cd ~/opt/src \
	&& wget http://xmlsoft.org/download/libxml2-${LIBXML2_VERSION}.tar.gz \
	&& tar xf libxml2-${LIBXML2_VERSION}.tar.gz \
	&& cd libxml2-${LIBXML2_VERSION} \
	&& emconfigure ./configure --prefix=/opt --disable-shared \
	&& make \
	&& make install \
	&& ln -s /opt/include/libxml2/libxml /opt/include/libxml

RUN cd ~/opt/src \
	&& git clone https://github.com/Qalculate/libqalculate.git \
	&& cd libqalculate \
	&& export NOCONFIGURE=1 NO_AUTOMAKE=1 \
	&& ./autogen.sh \
	&& export LIBXML_CFLAGS="-I/opt/include" LIBXML_LIBS="-L/opt/lib -lxml2" \
	&& export CFLAGS="-I/opt/include" LDFLAGS="-L/opt/lib" \
	&& emconfigure ./configure --prefix=/opt --without-libcurl --without-icu --enable-compiled-definitions --disable-nls --disable-shared --with-gnuplot-call=byo \
	&& cd data \
	&& make \
	&& cd ../libqalculate \
	&& make \
	&& make install

FROM --platform=linux/amd64 ubuntu:latest

COPY --from=builder /opt/include /opt/include
COPY --from=builder /opt/lib /opt/lib
COPY --from=builder /emsdk /emsdk

ENV EMSDK /emsdk \
	PATH="/emsdk:/emsdk/upstream/emscripten:/emsdk/node/${EM_NODE_VERSION}/bin:${PATH}"

RUN apt update \
	&& apt install -y --no-install-recommends default-jre-headless python3-minimal \
	&& apt-get -y clean \
	&& apt-get -y autoclean \
	&& apt-get -y autoremove \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/cache/debconf/*-old \
	&& rm -rf /usr/share/doc/* \
	&& rm -rf /usr/share/man/?? \
	&& rm -rf /usr/share/man/??_*