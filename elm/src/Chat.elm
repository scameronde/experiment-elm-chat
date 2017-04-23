module Chat exposing (Msg, Model, init, update, view, subscriptions)

import Html exposing (..)
import Bootstrap.Grid as Grid
import Model
import Lens exposing (..)
import BusinessTypes exposing (..)
import ChatRooms
import ChatRoom


{-| This is an example for a "product type" module. A "product type" module has no UI or logic by itself,
but has children. The children are all active at the same time (usually displayed at the same time) and
must be coordinated by the "product type" module.

There is another type of aggregator module, the "sum type" module. See ChatClient.elm for an example.
-}
type Msg
    = ChatRoomsMsg ChatRooms.Msg
    | ChatRoomMsg ChatRoom.Msg


type alias Model =
    { participant : Participant
    , chatRoomModel : Maybe ChatRoom.Model
    , chatRoomsModel : ChatRooms.Model
    }


init : Participant -> ( Model, Cmd Msg )
init participant =
    Model.create Model
        |> Model.set participant
        |> Model.set Nothing
        |> Model.combine ChatRoomsMsg ChatRooms.init
        |> Model.run


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChatRoomsMsg (ChatRooms.Selected chatRoom) ->
            Model.map (Just >> fset øchatRoomModel model) ChatRoomMsg (ChatRoom.init model.participant chatRoom)

        ChatRoomsMsg (ChatRooms.Deselected) ->
            fset øchatRoomModel model Nothing ! []

        ChatRoomsMsg msg_ ->
            Model.map (fset øchatRoomsModel model) ChatRoomsMsg (ChatRooms.update msg_ model.chatRoomsModel)

        ChatRoomMsg msg_ ->
            case model.chatRoomModel of
                Just model_ ->
                    Model.map (Just >> fset øchatRoomModel model) ChatRoomMsg (ChatRoom.update msg_ model_)

                Nothing ->
                    model ! []


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ Grid.row []
            [ Grid.col []
                [ Html.map ChatRoomsMsg (ChatRooms.view model.chatRoomsModel)
                ]
            , Grid.col []
                [ case model.chatRoomModel of
                    Just model_ ->
                        Html.map ChatRoomMsg (ChatRoom.view model_)

                    _ ->
                        text ""
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map ChatRoomsMsg (ChatRooms.subscriptions model.chatRoomsModel)
        , case model.chatRoomModel of
            Just model_ ->
                Sub.map ChatRoomMsg (ChatRoom.subscriptions model_)

            _ ->
                Sub.none
        ]


øparticipant : Lens { b | participant : a } a
øparticipant =
    lens .participant (\a b -> { b | participant = a })


øchatRoomModel : Lens { b | chatRoomModel : a } a
øchatRoomModel =
    lens .chatRoomModel (\a b -> { b | chatRoomModel = a })


øchatRoomsModel : Lens { b | chatRoomsModel : a } a
øchatRoomsModel =
    lens .chatRoomsModel (\a b -> { b | chatRoomsModel = a })
