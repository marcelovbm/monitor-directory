package br.com.equals.monitordirectory.config;

import java.io.IOException;

import org.apache.camel.LoggingLevel;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.spi.IdempotentRepository;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class RouteConfig extends RouteBuilder {

	private final IdempotentRepository idempotentRepository;

	@Override
	public void configure() throws Exception {

		onException(IOException.class).handled(true)
				.log(LoggingLevel.WARN, "IOException occurred due: ${exception.message}").transform()
				.simple("Error ${exception.message}").to("mock:error");

		from("file:///tmp?delete=true&shuffle=true&readLock=idempotent&idempotentRepository=#fileConsumed&bridgeErrorHandler=true&readLockRemoveOnCommit=true&readLockLoggingLevel=WARN")
				.idempotentConsumer(header("CamelFileName").append(header("CamelFileLength").regexReplaceAll(" ", "")), idempotentRepository)
				.threads(10)
				.log("File Consumed: ${in.headers.CamelFileName}")
				.to("file:///home/marcelomagrinelli/Documentos/teste_saida");
	}

}
