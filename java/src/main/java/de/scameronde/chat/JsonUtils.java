package de.scameronde.chat;

import static javaslang.API.None;

import java.io.IOException;
import java.io.StringWriter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import javaslang.API;
import javaslang.control.Either;
import javaslang.control.Option;
import javaslang.jackson.datatype.JavaslangModule;

class JsonUtils {
  static <T> Either<Exception, Option<String>> dataToJson(Option<T> data) {
    if (data.isDefined()) {
      return internalDataToJson(data.get()).map(API::Some);
    }
    else {
      return Either.right(None());
    }
  }

  static <T> Either<Exception, String> dataToJson(T data) {
    return internalDataToJson(data);
  }

  private static <T> Either<Exception, String> internalDataToJson(T data) {
    try {
      ObjectMapper mapper = new ObjectMapper();
      mapper.registerModule(new JavaslangModule());
      mapper.enable(SerializationFeature.INDENT_OUTPUT);
      StringWriter sw = new StringWriter();
      mapper.writeValue(sw, data);
      sw.close();
      return Either.right(sw.toString());
    }
    catch (IOException e) {
      e.printStackTrace();
      return Either.left(e);
    }
  }

  static <T> Either<Exception, T> jsonToData(String json, Class<T> clazz) {
    try {
      ObjectMapper mapper = new ObjectMapper();
      mapper.registerModule(new JavaslangModule());
      T creation = mapper.readValue(json, clazz);
      return Either.right(creation);
    }
    catch (IOException e) {
      e.printStackTrace();
      return Either.left(e);
    }
  }
}
