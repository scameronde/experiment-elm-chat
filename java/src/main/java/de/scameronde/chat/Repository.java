package de.scameronde.chat;


import de.scameronde.chat.businesstypes.ChatRoom;
import de.scameronde.chat.businesstypes.MessageLog;
import de.scameronde.chat.businesstypes.Participant;

import javaslang.collection.List;
import javaslang.control.Option;

public interface Repository {
  String addParticipant(Participant participant);

  Option<Participant> login(String participantName);

  List<ChatRoom> getChatRooms();

  String addChatRoom(ChatRoom chatRoom);

  void deleteChatRoom(ChatRoom chatRoom);

  void addMessage(ChatRoom chatRoom, String message, Participant participant);

  MessageLog getMessageLog(ChatRoom chatRoom);
}
