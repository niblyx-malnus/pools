|%
+$  id       [host=ship name=term]
:: graylist - blacklist and whitelist
:: automatic request handling
:: | auto reject or & auto accept
:: eventually graylist should allow for
:: custom functions from ship to (unit ?)
::
+$  graylist
  $:  ship=(map ship ?)       :: black/whitelisted ships
      rank=(map rank:title ?) :: black/whitelisted ranks (i.e. banning comets)
      rest=(unit ?)           :: auto reject/accept remaining
  ==
::
+$  pool
  $:  members=(set ship)                        :: already joined (includes host)
      invited=(map ship (pair time (unit ?)))   :: outgoing
      requested=(map ship (pair time (unit ?))) :: incoming
      receipts=(map ship (pair time ?))         :: | invite nacked; & invite acked
      =graylist                                 :: automatic accept/reject
      dudes=(set dude:gall)                     :: eventual userspace permissioning
  ==
:: each field update is a total field replacement
::
+$  field
  $%  [%ship p=(each [ship ?] ship)]
      [%rank p=(each [rank:title ?] rank:title)]
      [%rest p=(unit ?)]
      [%dude p=(each dude:gall dude:gall)]
      [%graylist =graylist]
  ==
::
+$  crud-command
  %+  pair  id
  $%  [%create fields=(list field)]
      [%update fields=(list field)]
      [%delete ~]
  ==
:: auto-generate unique id
::
+$  vent-id         (pair @p @da)
:: create an id based on a name
::
+$  create-command  [name=@t fields=(list field)]
:: vent request, not to be confused with membership request
::
+$  create-request  (pair vent-id create-command)
::
+$  invite-command
  %+  pair  id
  $%  [%invite =ship]
      [%cancel =ship]
      [%kick =ship]   :: kick a member
      [%accept ~]
      [%reject ~]
  ==
::
+$  request-command
  %+  pair  id
  $%  [%request ~]
      [%cancel ~]            
      [%leave ~]      :: leave a pool
      [%accept =ship]
      [%reject =ship]
  ==
::
+$  invite-gesture
  %+  pair  id
  $?  %invite         :: host to invitee
      %cancel         :: host to invitee
      %accept         :: invitee to host
      %reject         :: invitee to host
  ==
::
+$  request-gesture
  %+  pair  id
  $?  %request        :: requester to host
      %cancel         :: requester to host
      %accept         :: host to requester
      %reject         :: host to requester
  ==
::
+$  pool-update
  $%  field
      [%pool =pool]
      [%member p=(each ship ship)]
      [%invited p=(each [ship (pair time (unit ?))] ship)]
      [%requested p=(each [ship (pair time (unit ?))] ship)]
      [%receipt p=(each [ship (pair time ?)] ship)]
  ==
::
+$  home-update
  $%  [%pool p=(each id id)] :: new pool watched or created
      [%invite p=(each [id (pair time (unit ?))] id)]
      [%request p=(each [id (pair time (unit ?))] id)]
      [%receipt p=(each [id (pair time ?)] id)]
  ==
::
+$  peek
  $%  [%pools pools=(map id pool)]
      [%pool =pool]
      [%invites invites=(map id (pair time (unit ?)))]
      [%requests requests=(map id (pair time (unit ?)))]
      [%receipts receipts=(map id (pair time ?))]
  ==
--
