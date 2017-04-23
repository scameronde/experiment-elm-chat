module ChatClient exposing (..)

import Html exposing (..)
import Bootstrap.Grid as Grid
import Model
import Login
import Chat


{-| This is an example for a "sum type" module. A "sum type" module has no UI or logic by itself,
but has children. It has only one child active at most at a time. It can switch between its children,
depending on messages send by the active child.

There is another type of aggregator module, the "product type" module. See Chat.elm for an example.
-}
type Msg
    = LoginMsg Login.Msg
    | ChatMsg Chat.Msg


type Model
    = LoginModel Login.Model
    | ChatModel Chat.Model


init : ( Model, Cmd Msg )
init =
    Model.map LoginModel LoginMsg (Login.init)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( LoginMsg (Login.Login participant), LoginModel model_ ) ->
            Model.map ChatModel ChatMsg (Chat.init participant)

        ( LoginMsg msg_, LoginModel model_ ) ->
            Model.map LoginModel LoginMsg (Login.update msg_ model_)

        ( ChatMsg msg_, ChatModel model_ ) ->
            Model.map ChatModel ChatMsg (Chat.update msg_ model_)

        _ ->
            Debug.log "Stray combiniation of Model and Message found" ( model, Cmd.none )


viewMainArea : Model -> Html Msg
viewMainArea model =
    case model of
        LoginModel model_ ->
            Html.map LoginMsg (Login.view model_)

        ChatModel model_ ->
            Html.map ChatMsg (Chat.view model_)


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ Grid.row []
            [ Grid.col []
                [ case model of
                    LoginModel model_ ->
                        Html.map LoginMsg (Login.view model_)

                    ChatModel model_ ->
                        Html.map ChatMsg (Chat.view model_)
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        LoginModel model ->
            Sub.map LoginMsg (Login.subscriptions model)

        ChatModel model ->
            Sub.map ChatMsg (Chat.subscriptions model)



-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
