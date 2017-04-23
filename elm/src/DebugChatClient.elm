module DebugChatClient exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Model
import Lens exposing (..)
import ChatClient


type alias Flags =
    { debug : Bool }


type Msg
    = ChatClientMsg ChatClient.Msg


type alias Model =
    { debug : Bool
    , chatClientModel : ChatClient.Model
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    Model.create Model
        |> Model.set flags.debug
        |> Model.combine ChatClientMsg ChatClient.init
        |> Model.run


update : Msg -> Model -> ( Model, Cmd Msg )
update (ChatClientMsg msg) model =
    Model.map (fset øchatClientModel model) ChatClientMsg (ChatClient.update msg model.chatClientModel)


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ Grid.row []
            [ Grid.col []
                [ Html.map
                    ChatClientMsg
                    (ChatClient.view model.chatClientModel)
                ]
            ]
        , Grid.row []
            [ Grid.col []
                [ if model.debug then
                    div [ class "debug" ] [ text <| toString model ]
                  else
                    div [] []
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ChatClientMsg (ChatClient.subscriptions model.chatClientModel)



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


øchatClientModel : Lens { b | chatClientModel : a } a
øchatClientModel =
    lens .chatClientModel (\a b -> { b | chatClientModel = a })
