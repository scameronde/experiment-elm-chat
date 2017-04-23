module ChatRooms exposing (Msg(Selected, Deselected), Model, init, update, view, subscriptions)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Bootstrap.Grid as Grid
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Table as Table
import Bootstrap.Button as Button
import Dialog
import Http
import BusinessTypes exposing (..)
import RestClient
import Cmd exposing (..)
import Lens exposing (..)
import Time


-- MODEL


type RemoteRefreshingData e a
    = NotAsked
    | Loading
    | Updating a
    | Success a
    | Failure e


type Msg
    = Selected ChatRoom
    | Deselected
    | SelectChatRoom Id
    | DeleteChatRoom Id
    | DeleteChatRoomAcknowledge
    | DeleteChatRoomCancel
    | DeleteChatRoomResult (Result Http.Error ())
    | ChangeField Field String
    | PostChatRoom Model
    | PostChatRoomResult (Result Http.Error Id)
    | GetChatRooms Time.Time
    | GetChatRoomsResult (Result Http.Error (List ChatRoom))


type Field
    = Title


type alias Model =
    { chatRooms : RemoteRefreshingData String (List ChatRoom)
    , selectedChatRoomId : Maybe Id
    , chatRoomIdToDelete : Maybe Id
    , newChatRoomTitle : String
    , error : String
    }


init : ( Model, Cmd Msg )
init =
    { chatRooms = NotAsked
    , selectedChatRoomId = Nothing
    , chatRoomIdToDelete = Nothing
    , newChatRoomTitle = ""
    , error = ""
    }
        ! [ RestClient.getChatRooms GetChatRoomsResult ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- select or deselect a chat room
        SelectChatRoom id ->
            selectChatRoom id model

        -- enter the title for a new chat room
        ChangeField Title title ->
            (model |> set ønewChatRoomTitle title)
                ! []

        -- add a new chat room
        PostChatRoom model ->
            (model |> set ønewChatRoomTitle "")
                ! [ RestClient.postChatRoom (ChatRoom (Id "") model.newChatRoomTitle) PostChatRoomResult ]

        PostChatRoomResult (Ok id) ->
            (model |> set øerror "")
                ! [ RestClient.getChatRooms GetChatRoomsResult ]

        PostChatRoomResult (Err error) ->
            (model
                |> set øerror (toString error)
                |> set øselectedChatRoomId Nothing
                |> set øchatRoomIdToDelete Nothing
            )
                ! [ toCmd Deselected ]

        -- get available chat rooms
        GetChatRooms time ->
            (model
                |> set øchatRooms
                    (case model.chatRooms of
                        Success a ->
                            Updating a

                        Updating a ->
                            Updating a

                        _ ->
                            Loading
                    )
            )
                ! [ RestClient.getChatRooms GetChatRoomsResult ]

        GetChatRoomsResult (Ok chatRooms) ->
            updateChatRoomList chatRooms model

        GetChatRoomsResult (Err error) ->
            (model
                |> set øerror (toString error)
                |> set øchatRooms (Failure (toString error))
                |> set øselectedChatRoomId Nothing
                |> set øchatRoomIdToDelete Nothing
            )
                ! [ toCmd Deselected ]

        -- delete chat room
        DeleteChatRoom id ->
            (model |> set øchatRoomIdToDelete (Just id))
                ! []

        DeleteChatRoomAcknowledge ->
            deleteChatRoom model

        DeleteChatRoomCancel ->
            (model |> set øchatRoomIdToDelete Nothing)
                ! []

        DeleteChatRoomResult _ ->
            model ! []

        -- for external communication
        Selected chatRoom ->
            model ! []

        Deselected ->
            model ! []


findChatRoom : Id -> List ChatRoom -> Maybe ChatRoom
findChatRoom id chatRooms =
    List.filter (\chatRoom -> chatRoom.id == id) chatRooms |> List.head


selectChatRoom : Id -> Model -> ( Model, Cmd Msg )
selectChatRoom id model =
    if (model.selectedChatRoomId == Just id) then
        (model |> set øselectedChatRoomId Nothing)
            ! [ toCmd Deselected ]
    else
        case model.chatRooms of
            Updating a ->
                selectFromAvailableChatRoom id a model

            Success a ->
                selectFromAvailableChatRoom id a model

            _ ->
                (model |> set øselectedChatRoomId Nothing)
                    ! [ toCmd Deselected ]


selectFromAvailableChatRoom : Id -> List ChatRoom -> Model -> ( Model, Cmd Msg )
selectFromAvailableChatRoom id chatRooms model =
    case findChatRoom id chatRooms of
        Nothing ->
            (model |> set øselectedChatRoomId Nothing)
                ! [ toCmd Deselected ]

        Just chatRoom ->
            (model |> set øselectedChatRoomId (Just id))
                ! [ toCmd (Selected chatRoom) ]


updateChatRoomList : List ChatRoom -> Model -> ( Model, Cmd Msg )
updateChatRoomList chatRooms model =
    let
        newModel =
            model
                |> set øchatRooms (Success (List.sortBy .title chatRooms))
    in
        case model.selectedChatRoomId of
            Nothing ->
                newModel ! []

            Just id ->
                case findChatRoom id chatRooms of
                    Nothing ->
                        (newModel |> set øselectedChatRoomId Nothing)
                            ! [ toCmd Deselected ]

                    Just chatRoom ->
                        newModel ! []


deleteChatRoom : Model -> ( Model, Cmd Msg )
deleteChatRoom model =
    let
        newModel =
            model |> set øchatRoomIdToDelete Nothing
    in
        case ( model.chatRoomIdToDelete, model.selectedChatRoomId ) of
            ( Just idToDelete, Just selectedId ) ->
                if idToDelete == selectedId then
                    (newModel |> set øselectedChatRoomId Nothing)
                        ! [ toCmd Deselected
                          , RestClient.deleteChatRoom idToDelete DeleteChatRoomResult
                          ]
                else
                    newModel
                        ! [ RestClient.deleteChatRoom idToDelete DeleteChatRoomResult ]

            ( Just idToDelete, Nothing ) ->
                newModel
                    ! [ RestClient.deleteChatRoom idToDelete DeleteChatRoomResult ]

            ( Nothing, _ ) ->
                newModel ! []



-- VIEW


viewChatRooms : Model -> Html Msg
viewChatRooms model =
    let
        ( txt, list, selection ) =
            case model.chatRooms of
                NotAsked ->
                    ( "not asked", [], Nothing )

                Loading ->
                    ( "loading ...", [], Nothing )

                Updating a ->
                    ( "updating ...", a, model.selectedChatRoomId )

                Success a ->
                    ( "OK", a, model.selectedChatRoomId )

                Failure e ->
                    ( "Error: " ++ e, [], Nothing )
    in
        div []
            [ div [ class "info" ] [ text txt ]
            , viewChatRoomList list selection
            ]


viewChatRoomList : List ChatRoom -> Maybe Id -> Html Msg
viewChatRoomList chatRooms selection =
    Table.table
        { options = [ Table.striped, Table.hover ]
        , thead =
            Table.thead []
                [ Table.tr []
                    [ Table.th [] [ text "Available Chat Rooms" ]
                    , Table.th [] [ text "Actions" ]
                    ]
                ]
        , tbody =
            Table.tbody []
                (chatRooms
                    |> List.map
                        (\chatRoom ->
                            Table.tr (rowClass chatRoom selection)
                                [ Table.td [ Table.cellAttr (onClick (SelectChatRoom chatRoom.id)) ]
                                    [ text chatRoom.title
                                    ]
                                , Table.td []
                                    [ Button.button
                                        [ Button.danger
                                        , Button.small
                                        , Button.onClick (DeleteChatRoom chatRoom.id)
                                        ]
                                        [ text "X" ]
                                    ]
                                ]
                        )
                )
        }


rowClass : ChatRoom -> Maybe Id -> List (Table.RowOption msg)
rowClass chatRoom selection =
    if (selection == Just chatRoom.id) then
        [ Table.rowInfo ]
    else
        []


viewNewChatRoom : Model -> Html Msg
viewNewChatRoom model =
    Form.form [ onSubmit <| PostChatRoom model ]
        [ Form.group []
            [ Form.label [ for "titleInput" ] [ text "New Chat Room" ]
            , Input.text [ Input.id "titleInput", Input.onInput <| ChangeField Title ]
            ]
        , Button.button
            [ Button.primary
            , Button.disabled ((model.newChatRoomTitle |> String.trim |> String.length) == 0)
            ]
            [ text "Create" ]
        ]


viewDialog : Model -> Html Msg
viewDialog model =
    Dialog.view
        (if model.chatRoomIdToDelete /= Nothing then
            Just (dialogConfig model)
         else
            Nothing
        )


dialogConfig : Model -> Dialog.Config Msg
dialogConfig model =
    { closeMessage = Just DeleteChatRoomAcknowledge
    , containerClass = Nothing
    , header = Just (h3 [] [ text "Delete chat room" ])
    , body = Just (text ("Really delete chat room?"))
    , footer =
        Just
            (div []
                [ Button.button
                    [ Button.danger
                    , Button.onClick DeleteChatRoomAcknowledge
                    ]
                    [ text "OK" ]
                , Button.button [ Button.onClick DeleteChatRoomCancel ] [ text "Cancel" ]
                ]
            )
    }


view : Model -> Html Msg
view model =
    Grid.containerFluid []
        [ Grid.row []
            [ Grid.col []
                [ h2 [] [ text "Chat Room Selection" ]
                , viewChatRooms model
                , viewNewChatRoom model
                , viewDialog model
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every Time.second GetChatRooms



-- Lenses


øchatRooms : Lens { b | chatRooms : a } a
øchatRooms =
    lens .chatRooms (\a b -> { b | chatRooms = a })


øselectedChatRoomId : Lens { b | selectedChatRoomId : a } a
øselectedChatRoomId =
    lens .selectedChatRoomId (\a b -> { b | selectedChatRoomId = a })


øchatRoomIdToDelete : Lens { b | chatRoomIdToDelete : a } a
øchatRoomIdToDelete =
    lens .chatRoomIdToDelete (\a b -> { b | chatRoomIdToDelete = a })


ønewChatRoomTitle : Lens { b | newChatRoomTitle : a } a
ønewChatRoomTitle =
    lens .newChatRoomTitle (\a b -> { b | newChatRoomTitle = a })
