package de.scameronde.chat;

import static javaslang.API.List;
import static javaslang.API.Map;

import de.scameronde.chat.businesstypes.ChatRoom;
import de.scameronde.chat.businesstypes.MessageLog;
import de.scameronde.chat.businesstypes.Participant;

import javaslang.collection.List;
import javaslang.collection.Map;
import javaslang.control.Option;

public class InMemoryRepository implements Repository {
  private static Integer idcounter = 100;

  private List<Participant> participants;
  private List<ChatRoom> chatRooms;
  private Map<ChatRoom, String> logs;

  InMemoryRepository() {
    ChatRoom chatRoom1 = new ChatRoom("1", "Room 1");
    ChatRoom chatRoom2 = new ChatRoom("2", "Room 2");
    chatRooms = List(chatRoom1, chatRoom2);
    logs = Map(chatRoom1, "").put(chatRoom2, "");
    participants = List(
        new Participant("", "Homer"),
        new Participant("", "Marge"),
        new Participant("", "Maggie"),
        new Participant("", "Bart"),
        new Participant("", "Lisa"),
        new Participant("", "Burns"),
        new Participant("", "Smithers"),
        new Participant("", "Ned"),
        new Participant("", "Rod"),
        new Participant("", "Todd"),
        new Participant("", "Leny"),
        new Participant("", "Carl"));
  }

  @Override
  public synchronized String addParticipant(Participant participant) {
    String id = String.valueOf(idcounter++);
    participant.setId(id);
    participants = participants.append(participant);
    return id;
  }

  @Override
  public Option<Participant> login(String participantName) {
    return participants.find(p -> p.getName().equals(participantName));
  }

  @Override
  public List<ChatRoom> getChatRooms() {
    throttle(2);
    return chatRooms;
  }

  @Override
  public synchronized String addChatRoom(ChatRoom chatRoom) {
    String id = String.valueOf(idcounter++);
    chatRoom.setId(id);
    chatRooms = chatRooms.append(chatRoom);
    logs = logs.put(chatRoom, "");
    return id;
  }

  @Override
  public synchronized void deleteChatRoom(ChatRoom chatRoom) {
    chatRooms = chatRooms.remove(chatRoom);
    logs = logs.remove(chatRoom);
  }

  @Override
  public synchronized void addMessage(ChatRoom chatRoom, String message, Participant participant) {
    logs = logs.put(chatRoom, message, String::concat);
  }

  @Override
  public MessageLog getMessageLog(ChatRoom chatRoom) {
    return new MessageLog(logs.getOrElse(chatRoom, ""));
  }

  private void throttle(long millis) {
    try {
      Thread.sleep(millis);
    }
    catch (InterruptedException e) {
      e.printStackTrace();  // TODO: handle exception
    }
  }
}
