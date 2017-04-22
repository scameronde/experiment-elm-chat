module BusinessTypes exposing (..)

import Lens exposing (..)


type Id
    = Id String


type alias Participant =
    { id : Id
    , name : String
    }


type alias ChatRoom =
    { id : Id
    , title : String
    }


type alias ChatRegistration =
    { participant : Participant
    , chatRoom : ChatRoom
    }


type alias Message =
    { message : String
    }


type alias MessageLog =
    { messageLog : String
    }


type ChatCommand
    = Register ChatRegistration
    | NewMessage Message



-- Utilities to make the handling of the busioness types easier


type alias Identifyable a =
    { a | id : Id }


øid : Lens { b | id : a } a
øid =
    lens .id (\a b -> { b | id = a })


øname : Lens { b | name : a } a
øname =
    lens .name (\a b -> { b | name = a })


øtitle : Lens { b | title : a } a
øtitle =
    lens .title (\a b -> { b | title = a })


øparticipant : Lens { a | participant : b } b
øparticipant =
    lens .participant (\a b -> { b | participant = a })


øchatRoom : Lens { b | chatRoom : a } a
øchatRoom =
    lens .chatRoom (\a b -> { b | chatRoom = a })


ømessage : Lens { b | message : a } a
ømessage =
    lens .message (\a b -> { b | message = a })


ømessageLog : Lens { b | messageLog : a } a
ømessageLog =
    lens .messageLog (\a b -> { b | messageLog = a })


øerror : Lens { b | error : a } a
øerror =
    lens .error (\a b -> { b | error = a })
