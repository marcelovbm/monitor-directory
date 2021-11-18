package br.com.equals.monitoradiretorio.config;

import javax.sql.DataSource;

import org.apache.camel.processor.idempotent.jdbc.JdbcMessageIdRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import lombok.RequiredArgsConstructor;

@Configuration
@RequiredArgsConstructor
public class IdempotentRepoConf {

	private final DataSource dataSource;

	@Bean
	public JdbcMessageIdRepository fileConsumed() {
		return new JdbcMessageIdRepository(dataSource, "FileConsumed");
	}

}
