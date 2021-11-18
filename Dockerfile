# syntax=docker/dockerfile:1
#Imagem responsável por realizar o build da aplicação
#232.46 MB
FROM maven:3.8.3-openjdk-11-slim as build

WORKDIR /workspace/app

COPY pom.xml .
RUN mvn dependency:go-offline --batch-mode

COPY src src
#1 Realizando a criação do pacote da aplicação.
#2 Criando diretorio das dependecias.
#3 Descompactando os arquivos do fat jar.
#4 Fazendo a exportanção de todos os modulos utilizados.
RUN mvn package -DskipTests \
-Dmaven.javadoc.skip=true \
--batch-mode \
	&& mkdir -p target/dependency \
	&& (cd target/dependency; jar --extract -f ../*.jar) \
	&& jdeps --print-module-deps \
--multi-release 9 \
--recursive \
--ignore-missing-deps \
--class-path 'target/dependency/BOOT-INF/lib/*' \
target/*.jar > java.modules

#Imagem para realizar a criação da JVM personalizada,
#contendo apenas os modulos utilizados pela aplicação.
#50.21 MB
FROM alpine:latest as packager

ENV JAVA_MINIMAL="/opt/java-minimal"

COPY --from=build /workspace/app/java.modules .

#1 Instalando JAVA na versão 11.
#2 Realizando a criação da JVM customizada.
RUN apk --no-cache add openjdk11-jdk openjdk11-jmods \
&& /usr/lib/jvm/java-11-openjdk/bin/jlink \
 --add-modules $(cat java.modules) \
 --compress=2 \
 --strip-debug \
 --no-header-files \
 --no-man-pages \
 --ignore-signing-information \
 --output "$JAVA_MINIMAL" 
    
#Imagem que será responsável por rodas a aplicação.
#2.48 MB
FROM alpine:latest

ENV JAVA_HOME=/opt/java-minimal
ENV PATH="$PATH:$JAVA_HOME/bin"

COPY --from=packager "$JAVA_HOME" "$JAVA_HOME"

RUN adduser --system spring
USER spring

VOLUME /tmp

ARG DEPENDENCY=/workspace/app/target/dependency

COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

ENTRYPOINT ["java","--class-path","app:app/lib/*","br.com.equals.monitordirectory.MonitoradiretorioApplication"]