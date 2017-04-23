module ChatRoom exposing (Msg, Model, init, update, view, subscriptions)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Bootstrap.Grid as Grid
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Button as Button
import Lens exposing (..)
import RestClient
import WebSocket
import WebSocketClient
import BusinessTypes exposing (..)


type Msg
    = SetChatHistory (Result Http.Error MessageLog)
    | ChangeField Field String
    | SendMessage String
    | ReceivedMessage String


type Field
    = NewMessage


type alias Model =
    { participant : Participant
    , chatRoom : ChatRoom
    , message : String
    , messageLog : String
    , error : String
    }


init : Participant -> ChatRoom -> ( Model, Cmd Msg )
init participant chatRoom =
    { participant = participant
    , chatRoom = chatRoom
    , message = ""
    , messageLog = ""
    , error = ""
    }
        ! [ WebSocketClient.sendRegistration (ChatRegistration participant chatRoom)
          , RestClient.getChatRoom chatRoom.id SetChatHistory
          ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeField NewMessage message ->
            (model |> set ømessage message) ! []

        SendMessage message ->
            (model |> set ømessage "") ! [ WebSocketClient.sendMessage (Message message) ]

        ReceivedMessage message ->
            (model |> set ømessageLog (model.messageLog ++ message)) ! []

        SetChatHistory (Ok messageLog) ->
            (model |> set ømessageLog messageLog.messageLog) ! []

        SetChatHistory (Err error) ->
            (model |> set øerror (toString error)) ! []


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ Grid.row []
            [ Grid.col []
                [ h2 [] [ text model.chatRoom.title ]
                , Textarea.textarea [ Textarea.rows 20, Textarea.value model.messageLog ]
                , Form.formInline [ onSubmit <| SendMessage model.message ]
                    [ Input.text
                        [ Input.placeholder <| model.participant.name ++ ": Enter message"
                        , Input.value model.message
                        , Input.onInput <| ChangeField NewMessage
                        , Input.attrs <| [ size 30 ]
                        ]
                    , Button.button [ Button.primary ] [ text "Send" ]
                    ]
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://localhost:4567/chat" ReceivedMessage
