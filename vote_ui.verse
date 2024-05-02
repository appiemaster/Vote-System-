
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors/NamedColors }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /Fortnite.com/AI }
using { config.ui_config}

vote_ui := class(creative_device):

    var VoteUIPerPlayer : [agent]?canvas = map{}

    OverlayColorBlock : color_block = color_block:
        DefaultOpacity := 0.5

    var AllVoteItems : [button_quiet]vote_item = map{}
        
    TimerTextBlock : text_block = text_block{DefaultTextColor := White}

    var VoteItems : []vote_item = array{}

    @editable
    TestDevices : testing_devices = testing_devices{}

    @editable
    AllVoteInfo : []vote_item_options = array{}

    @editable
    VotingOptions : voting_options = voting_options{}

    @editable
    VotingUIStyle : voting_ui_style = voting_ui_style{}

    CloseBtnMessage<localizes> :message = "Close"
    
    CloseBtn : button_loud = button_loud{}

    OnBegin<override>()<suspends>:void=
        CloseBtn.SetText(CloseBtnMessage)
        OverlayColorBlock.SetColor(VotingUIStyle.BGColorOfEntireUI)
        OverlayColorBlock.SetOpacity(VotingUIStyle.BGOpacityOfEntireUI)
        spawn{AwaitButtonPress()}
        CreateVoteObjs()

    CreateVoteObjs():void=
        for(VoteInfo : AllVoteInfo):
            Print("{VoteInfo.VoteTitle}")
            VoteItem := vote_item:
                VoteTitle := VoteInfo.VoteTitle
                VoteImgSize := VoteInfo.VoteImgSize
                BGOpacityVoteItem := VoteInfo.BGOpacityVoteItem
                BGColorVoteItem := VoteInfo.BGColorVoteItem
                VoteImg := VoteInfo.VoteImg
                POILoc := VoteInfo.POILoc
                SetVotesAmountInButton := VotingOptions.SetVotesAmountInButton
            set VoteItems += array{VoteItem}
            
    AwaitButtonPress()<suspends>:void=
        loop:
            Agent := TestDevices.StartVoting.TriggeredEvent.Await()
            spawn{StartVoting()}

    StartVoting()<suspends>:void=
        for(Player : GetPlayspace().GetPlayers()):
            AddUI(Player)
            spawn{VoteTimer()}
        Sleep(VotingOptions.VotingTime * 1.0)
        for(Player : GetPlayspace().GetPlayers()):
            ManuallyRemoveUI(Player)
        var VoteInfos : vote_info = vote_info{HighestVoteAmount := 0, WinningVote := ""}
        var CorrectVoteItemInfo : vote_item = vote_item{}
        for(VoteItem : AllVoteItems):
            if(VoteItem.AmountOfVotes >= VoteInfos.HighestVoteAmount):
                set VoteInfos.HighestVoteAmount = VoteItem.AmountOfVotes
                set VoteInfos.WinningVote = VoteItem.VoteTitle
                set CorrectVoteItemInfo = VoteItem
        for(VoteItem : AllVoteItems):
            VoteItem.ResetVals()
        Print("The winner {VoteInfos.WinningVote} with {VoteInfos.HighestVoteAmount} votes")
        Sleep(2.0)
        for(Player : GetPlayspace().GetPlayers()):
            if(Player.GetFortCharacter[].TeleportTo[CorrectVoteItemInfo.POILoc, IdentityRotation()]){Print("aaaaa")}
    VoteTimer()<suspends>:void=
        var TimeLeft : int = VotingOptions.VotingTime
        loop:
            set TimeLeft -= 1
            TimerTextBlock.SetText(S2M("{TimeLeft} seconds left."))
            Sleep(1.0)
            if(TimeLeft = 0):
                break

    GetRandomVoteItems():void=
        set AllVoteItems = map{}
        var AddedItems : []vote_item = array{}
        for(I := 1..VotingOptions.VotingItemsAmount):
            loop:
                if:
                    RandomVoteItem := VoteItems[GetRandomInt(0, VoteItems.Length -1)]
                    not AddedItems.Find[RandomVoteItem]
                    set AllVoteItems[button_quiet{}] = RandomVoteItem
                then:
                    set AddedItems += array{RandomVoteItem}
                    break

    AddUI(Agent : agent):void=
        if(PlayerUI := GetPlayerUI[player[Agent]]):
            GetRandomVoteItems()
            PlayerUI.AddWidget(MakeVoteCanvas(Agent), player_ui_slot. InputMode := ui_input_mode.All)


    ManuallyRemoveUI(Agent : agent):void=
        if(PlayerUI := GetPlayerUI[player[Agent]], CanvasToRemove := VoteUIPerPlayer[Agent]?):
            PlayerUI.RemoveWidget(CanvasToRemove)

    RemoveVoteUI(WM : widget_message):void= 
        if(PlayerUI := GetPlayerUI[WM.Player], CanvasToRemove := VoteUIPerPlayer[WM.Player]?):
            PlayerUI.RemoveWidget(CanvasToRemove)
            if(btn := text_button_base[WM.Source]):
                Print("{btn.GetText()}")
    OnVoted(WM : widget_message):void=
        if(VoteItemObj := AllVoteItems[WM.Source]):
            VoteItemObj.IncreaseVote(WM.Player)
            Print("votin'.")
            for(OtherVoteItem : AllVoteItems, VoteItemObj <> OtherVoteItem):
                OtherVoteItem.RemoveAgentVote(WM.Player)
        else:
            Print("Fail", ?Color := Red)
    MakeVoteCanvas(Agent : agent):canvas=
        ItemsStackBox := stack_box{Orientation := orientation.Horizontal}
        CloseBtn.OnClick().Subscribe(RemoveVoteUI)
        for(VoteBtn -> VoteItem : AllVoteItems):
            set VoteItem.VoteButton = VoteBtn
            VoteBtn.OnClick().Subscribe(OnVoted)
            VoteItem.Init()
            ItemsStackBox.AddWidget(
                stack_box_slot:
                    Widget := VoteItem.MakeVoteItem()
                    Padding := margin{Left := 15.0, Right := 15.0}
            )
        TimerOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block:
                        DefaultColor := White
                        DefaultOpacity := 0.319
                    HorizontalAlignment := HorFill
                    VerticalAlignment := VerFill
                overlay_slot:
                    Widget := TimerTextBlock
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerCen
                    Padding := margin{Left := 15.0, Right := 15.0}
        VoteOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := OverlayColorBlock
                    HorizontalAlignment := HorFill
                    VerticalAlignment := VerFill
                overlay_slot:
                    Widget := ItemsStackBox
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerCen
                    Padding := margin{Bottom := 50.0}
                overlay_slot:
                    Widget := CloseBtn
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerBottom
                    Padding := margin{Bottom := 25.0}
                overlay_slot:
                    Widget := TimerOverlay
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerTop
                    Padding := margin{Top := 115.0}
        VoteCanvas := canvas:
            Slots :=array:
                canvas_slot:
                    Widget := VoteOverlay
                    Anchors := anchors:
                        Minimum := vector2{X:= 0.0, Y := 0.0},
                        Maximum :=  vector2{X:= 1.0, Y := 1.0}

                        
        if(set VoteUIPerPlayer[Agent] = option{VoteCanvas}){}
        return VoteCanvas




vote_item := class<unique>:

    var VoteButton : button_quiet = button_quiet{}

    @editable
    BGColorVoteItem : color = color{}

    SetVotesAmountInButton : logic = false
    

    POILoc : vector3 = vector3{}

    @editable
    BGOpacityVoteItem : type{_X:float where 0.0 <= _X, _X <= 1.0} = 0.5

    VoteImgSize : vector2 = vector2{X:= 345.833954, Y:= 232.656372}

    VoteAmountTextBlock : text_block = text_block{DefaultTextColor := White}

    VoteMsg<localizes>:message = "Vote!"

    VoteTitle : string = ""

    var AmountOfVotes : int = 0

    BGBlock : color_block = color_block:
        DefaultOpacity := 0.5
        DefaultDesiredSize :=  vector2{X:= 482.941589, Y:= 455.694702}
        DefaultColor := Purple

    var PlayersVoted : []agent = array{}

    VoteImg : vote_img = vote_img.ch5_map

    AllImgs : [vote_img]texture = map:
        vote_img.ch5_map => img.ch5_map

    Init():void=
        UpdateVoteText()
        BGBlock.SetColor(BGColorVoteItem)
        BGBlock.SetOpacity(BGOpacityVoteItem)


    ResetVals():void=
        set AmountOfVotes = 0
        set PlayersVoted = array{}
        UpdateVoteText()

    IncreaseVote(Agent : agent):void=
        if(not PlayersVoted.Find[Agent]):
            set AmountOfVotes += 1
            UpdateVoteText()
            set PlayersVoted += array{Agent}
            Print("add")

    RemoveAgentVote(Agent : agent):void=
        if:
            IndexToRemove := PlayersVoted.Find[Agent]
            TempArray := PlayersVoted.RemoveElement[IndexToRemove]
        then:
            set PlayersVoted = TempArray
            set AmountOfVotes -= 1
            UpdateVoteText()

    UpdateVoteText():void=
        if(SetVotesAmountInButton?):
            VoteButton.SetText(I2M(AmountOfVotes))
        else:
            VoteButton.SetText(VoteMsg)
            VoteAmountTextBlock.SetText(I2M(AmountOfVotes))
    MakeVoteItem():overlay=
        VoteItem := overlay:
            Slots := array:
                overlay_slot:
                    Widget := BGBlock
                    HorizontalAlignment := HorFill
                    VerticalAlignment := VerFill
                overlay_slot:
                    Widget := text_block:
                        DefaultTextColor := White
                        DefaultText := S2M(VoteTitle)
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerTop
                    Padding := margin{Top := 10.0}
                overlay_slot:
                    Widget := texture_block:
                        DefaultImage := if(VoteTexture := AllImgs[VoteImg]) then VoteTexture else img.ch5_map
                        DefaultDesiredSize := VoteImgSize
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerCen
                    Padding := margin{Bottom := 50.0}
                overlay_slot:
                    Widget := MakeLargeButton(vector2{X:= 319.63913, Y:= 59.783245}, VoteButton)
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerBottom
                    Padding := margin{Bottom := 15.0}
                overlay_slot:
                    Widget := VoteAmountTextBlock
                    HorizontalAlignment := HorCen
                    VerticalAlignment := VerBottom
                    Padding := margin{Bottom := 85.0}
        return VoteItem

vote_info := class<unique>:
    var HighestVoteAmount : int = 0
    var WinningVote : string = ""



voting_ui_style := class<concrete>:

    @editable
    BGColorOfEntireUI : color = color{}

    @editable
    BGOpacityOfEntireUI : type{_X:float where 0.0 <= _X, _X <= 1.0} = 0.5

voting_options := class<concrete>:

    @editable
    var VotingTime : type{_X:int where 1 <= _X, _X <= 200000} = 20

    @editable
    VotingItemsAmount : type{_X:int where 2 <= _X, _X <= 3} = 3

    @editable
    SetVotesAmountInButton : logic = false
vote_item_options := class<concrete>:

    @editable
    VoteTitle : string = ""

    @editable
    VoteImgSize : vector2 = vector2{X:= 345.833954, Y:= 232.656372}

    @editable
    VoteImg : vote_img = vote_img.ch5_map

    @editable
    BGColorVoteItem : color = color{}

    @editable
    BGOpacityVoteItem : type{_X:float where 0.0 <= _X, _X <= 1.0} = 0.5

    @editable
    POILoc : vector3 = vector3{}

testing_devices := class<concrete>:
    @editable
    StartVoting : trigger_device = trigger_device{}

vote_img := enum:
    ch5_map


