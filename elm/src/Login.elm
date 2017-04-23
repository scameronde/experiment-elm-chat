module Login exposing (Msg(..), Field(..), Model, init, update, view, subscriptions)

import Html exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events exposing (..)
import Http
import Bootstrap.Grid as Grid
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import BusinessTypes exposing (..)
import RestClient
import Cmd exposing (..)
import Lens exposing (..)


type Msg
    = Login Participant
    | GetParticipant
    | GetParticipantResult (Result Http.Error Participant)
    | ChangeField Field String


type alias Model =
    { name : String
    , error : String
    }


type Field
    = Name


init : ( Model, Cmd Msg )
init =
    { name = "", error = "" } ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeField Name name ->
            (model
                |> set øname name
                |> set øerror (updatedErrorMessage name model.error)
            )
                ! []

        GetParticipant ->
            if (String.isEmpty model.name) then
                model ! []
            else
                model ! [ RestClient.getParticipant model.name GetParticipantResult ]

        GetParticipantResult (Ok participant) ->
            model ! [ toCmd (Login participant) ]

        GetParticipantResult (Err error) ->
            (model
                |> set øerror (toString error)
            )
                ! []

        -- for external communication
        Login participant ->
            model ! []


updatedErrorMessage : String -> String -> String
updatedErrorMessage name error =
    if String.isEmpty name then
        ""
    else
        error


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ Grid.row []
            [ Grid.col []
                [ viewErrorMsg model "Wrong Credentials!" ]
            ]
        , Grid.row []
            [ Grid.col []
                [ Form.form [ onSubmit GetParticipant ]
                    [ Form.group []
                        [ Form.label [ for "nameInput" ] [ text "Your name" ]
                        , Input.text [ Input.id "nameInput", Input.onInput (ChangeField Name) ]
                        ]
                    , Button.button [ Button.primary, Button.disabled (noName model) ] [ text "OK" ]
                    ]
                ]
            ]
        ]


viewErrorMsg : Model -> String -> Html Msg
viewErrorMsg model msg =
    if (String.isEmpty model.error) then
        div [] []
    else
        div [ class "alert alert-danger" ] [ text msg ]


noError : Model -> Bool
noError model =
    String.isEmpty model.error


noName : Model -> Bool
noName model =
    String.isEmpty model.name


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
