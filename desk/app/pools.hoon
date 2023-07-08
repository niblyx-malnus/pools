:: A minimal "pool" membership manager.
:: A "pool" is a set of ships managed by a host.
::
:: %pools ONLY handles membership.
::
:: If you use %pools for your app:
:: - You are responsible for your own pool roles.
:: - You are responsible for your own pool metadata.
:: - You are responsible for the visiblity/discoverabilty of your pools.
:: - You are responsible for sending your own invite/request messages.
::
:: Only the host can invite/disinvite members.
:: Only the host can accept/reject membership requests.
:: Only the host can update pool settings.
:: To allow admin privileges or other kinds of permissions,
::   you must pass through another agent on the host ship.
::
/-  *pools
/+  dbug, verb, default-agent
:: Import during development to force compilation
::
/=  cc  /mar/pools/crud-command
/=  ic  /mar/pools/invite-command
/=  rc  /mar/pools/request-command
/=  ig  /mar/pools/invite-gesture
/=  rg  /mar/pools/request-gesture
/=  pu  /mar/pools/pool-update
/=  ph  /mar/pools/home-update
/=  pk  /mar/pools/peek
/=  co  /mar/pools/create-command
/=  cr  /mar/pools/create-request
|%
+$  state-0
  $:  %0
      pools=(map id pool)                    :: owned or joined pools
      invites=(map id (pair time (unit ?)))  :: incoming
      requests=(map id (pair time (unit ?))) :: outgoing
      receipts=(map id (pair time ?))        :: | request nacked; & request acked
  ==
+$  card  card:agent:gall
--
%-  agent:dbug
%+  verb  |
=|  state-0
=*  state  -
=<
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    hc    ~(. +> [bowl ~])
    cc    |=(cards=(list card) ~(. +> [bowl cards]))
++  on-init
  ^-  (quip card _this)
  `this
++  on-save   !>(state)
::
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  =/  old=state-0  !<(state-0 ole)
  =.  state  old
  `this
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %pools-create-command
    :: only you can command your own agent
    ::
    ?>  =(src our):bowl
    =/  req=create-request  [[our now]:bowl !<(create-command vase)]
    =^  cards  this
      (on-poke pools-create-request+!>(req))
    [cards this]
    ::
      %pools-create-request
    :: only you can command your own agent
    ::
    ?>  =(src our):bowl
    =/  [vid=vent-id cmd=create-command]  !<(create-request vase)
    =/  vent-path  /vent/(scot %p p.vid)/(scot %da q.vid)
    =/  =id  (unique-id:hc name.cmd)
    =^  cards  this
      (on-poke pools-crud-command+!>([id %create fields.cmd]))
    :_  this
    %+  welp  cards
    :~  [%give %fact ~[vent-path] pools-vent+!>(id)]
        [%give %kick ~[vent-path] ~]
    ==
    ::
      %pools-crud-command
    :: only you can command your own agent
    ::
    ?>  =(src our):bowl
    =/  cmd=crud-command  !<(crud-command vase)
    :: you must be the host of any pool you create
    :: only the host can modify pool settings
    :: only the host of a pool can delete that pool
    ::
    ?>  =(our.bowl host.p.cmd)
    ?-    +<.cmd
        %create
      ?>  ((sane %tas) name.p.cmd)
      ?<  (~(has by pools) p.cmd)
      =|  =pool
      =.  pool  (do-updates:hc pool fields.q.cmd)
      =.  members.pool  (~(put in members.pool) our.bowl)
      :_  this(pools (~(put by pools) p.cmd pool))
      [%give %fact ~[/home] pools-home-update+!>([%pool %& p.cmd])]~
      ::
        %update
      =/  =pool  (~(got by pools) p.cmd)
      =.  pool   (do-updates:hc pool fields.q.cmd)
      :_  this(pools (~(put by pools) p.cmd pool))
      :: give field updates
      ::
      =/  =path  /pool/(scot %p host.p.cmd)/[name.p.cmd]
      %+  turn  fields.q.cmd
      |=  =field
      [%give %fact ~[path] pools-pool-update+!>(field)]
      ::
        %delete
      :_  this(pools (~(del by pools) p.cmd))
      :~  [%give %fact ~[/home] pools-home-update+!>([%pool %| p.cmd])]
          [%give %kick ~[/pool/(scot %p host.p.cmd)/[name.p.cmd]] ~]
      ==
    ==
    ::
      %pools-invite-command
    :: only you can command your own agent
    ::
    ?>  =(src our):bowl
    =/  cmd=invite-command  !<(invite-command vase)
    ?-    +<.cmd
        %invite
      :: only the host can invite
      ::
      ?>  =(our.bowl host.p.cmd)
      :: add to invited
      ::
      =/  =pool  (~(got by pools) p.cmd)
      ?<  (~(has in members.pool) ship.q.cmd)
      ?<  (~(has by invited.pool) ship.q.cmd)
      =.  invited.pool
        (~(put by invited.pool) ship.q.cmd [now.bowl ~])
      :_  this(pools (~(put by pools) p.cmd pool))
      :~
        :: send invite gesture and follow wire for ack
        ::
        =/  =cage  pools-invite-gesture+!>([p.cmd %invite])
        =/  =wire  /invite/[(scot %p host.p.cmd)]/[name.p.cmd]
        [%pass wire %agent [ship.q.cmd dap.bowl] %poke cage]
        :: send %invited update
        ::
        =/  =path  /pool/(scot %p host.p.cmd)/[name.p.cmd]
        =/  upd=pool-update  [%invited %& ship.q.cmd [now.bowl ~]]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
      ==
      ::
        %cancel
      :: only the host can invite
      ::
      ?>  =(our.bowl host.p.cmd)
      :: remove from invited and receipts
      ::
      =/  =pool          (~(got by pools) p.cmd)
      =.  invited.pool   (~(del by invited.pool) ship.q.cmd)
      =.  receipts.pool  (~(del by receipts.pool) ship.q.cmd)
      :_  this(pools (~(put by pools) p.cmd pool))
      =/  =path  /pool/(scot %p host.p.cmd)/[name.p.cmd]
      :~
        :: send cancel gesture
        ::
        =/  =cage  pools-invite-gesture+!>([p.cmd %cancel])
        [%pass / %agent [ship.q.cmd dap.bowl] %poke cage]
        ::
        :: send %invited update
        ::
        =/  upd=pool-update  [%invited %| ship.q.cmd]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
        :: send %receipt update
        ::
        =/  upd=pool-update  [%receipt %| ship.q.cmd]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
      ==
      ::
        %kick
      :: only the host can kick members
      ::
      ?>  =(our.bowl host.p.cmd)
      :: cannot remove host as a member
      ::
      ?<  =(ship.q.cmd host.p.cmd)
      :: remove from members, invited, requested and receipts
      ::
      =/  =pool           (~(got by pools) p.cmd)
      =.  members.pool    (~(del in members.pool) ship.q.cmd)
      =.  invited.pool    (~(del by invited.pool) ship.q.cmd)
      =.  requested.pool  (~(del by requested.pool) ship.q.cmd)
      =.  receipts.pool   (~(del by receipts.pool) ship.q.cmd)
      :_  this(pools (~(put by pools) p.cmd pool))
      =/  =path  /pool/(scot %p host.p.cmd)/[name.p.cmd]
      :~
        :: kick from pool path
        ::
        [%give %kick ~[path] `ship.q.cmd]
        :: send %member update
        ::
        =/  upd=pool-update  [%member %| ship.q.cmd]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
        :: send %invited update
        ::
        =/  upd=pool-update  [%invited %| ship.q.cmd]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
        :: send %requested update
        ::
        =/  upd=pool-update  [%requested %| ship.q.cmd]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
        :: send %receipt update
        ::
        =/  upd=pool-update  [%receipt %| ship.q.cmd]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
      ==
      ::
        %accept
      :: cannot accept non-existent or already-determined invite
      ::
      ?~  inv=(~(get by invites) p.cmd)  ~|(%no-invite-outstanding !!)
      ?^  q.u.inv  ~|(%invite-already-determined !!)
      :: send accept gesture and follow wire for ack
      ::
      :_  this
      =/  =cage  pools-invite-gesture+!>([p.cmd %accept])
      =/  =wire  /accept-invite/[(scot %p host.p.cmd)]/[name.p.cmd]
      [%pass wire %agent [host.p.cmd dap.bowl] %poke cage]~
      ::
        %reject
      :: cannot reject non-existent or already-determined invite
      ::
      ?~  inv=(~(get by invites) p.cmd)  ~|(%no-invite-outstanding !!)
      ?^  q.u.inv  ~|(%invite-already-determined !!)
      :: send reject gesture
      :: 
      :_  this
      =/  =cage  pools-invite-gesture+!>([p.cmd %reject])
      =/  =wire  /reject-invite/[(scot %p host.p.cmd)]/[name.p.cmd]
      [%pass wire %agent [host.p.cmd dap.bowl] %poke cage]~
    ==
    ::
      %pools-request-command
    :: only you can command your own agent
    ::
    ?>  =(src our):bowl
    =/  cmd=request-command  !<(request-command vase)
    ?-    +<.cmd
        %request
      ?<  |((~(has by pools) p.cmd) (~(has by requests) p.cmd))
      :: add to requests
      ::
      :_  this(requests (~(put by requests) p.cmd [now.bowl ~]))
      :~
        =/  upd=home-update  [%request %& p.cmd [now.bowl ~]]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        :: send request gesture and follow wire for ack
        ::
        =/  =cage  pools-request-gesture+!>([p.cmd %request])
        =/  =wire  /request/[(scot %p host.p.cmd)]/[name.p.cmd]
        [%pass wire %agent [host.p.cmd dap.bowl] %poke cage]
      ==
      ::
        %cancel
      :: remove from requests and receipts
      ::
      =.  requests  (~(del by requests) p.cmd)
      :_  this(receipts (~(del by receipts) p.cmd))
      :~
        :: send home updates
        ::
        =/  upd=home-update  [%request %| p.cmd]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        =/  upd=home-update  [%receipt %| p.cmd]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        :: send cancel gesture
        ::
        =/  =cage  pools-request-gesture+!>([p.cmd %cancel])
        [%pass / %agent [host.p.cmd dap.bowl] %poke cage]
      ==
      ::
        %leave
      ?<  =(our.bowl host.p.cmd)
      :: remove pool
      ::
      :_  %=  this
            pools     (~(del by pools) p.cmd)
            invites   (~(del by invites) p.cmd)
            requests  (~(del by requests) p.cmd)
            receipts  (~(del by receipts) p.cmd)
          ==
      :~
        :: leave pool path
        ::
        =/  =wire  /pool/(scot %p host.p.cmd)/[name.p.cmd]
        [%pass wire %agent [host.p.cmd dap.bowl] %leave ~]
        :: send home updates
        ::
        =/  upd=home-update  [%pool %| p.cmd]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        =/  upd=home-update  [%invite %| p.cmd]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        =/  upd=home-update  [%request %| p.cmd]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        =/  upd=home-update  [%receipt %| p.cmd]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
      ==
      ::
        %accept
      :: only the host can accept/reject requests
      ::
      ?>  =(our.bowl host.p.cmd)
      :: cannot accept non-existent or already-determined request
      ::
      =/  =pool           (~(got by pools) p.cmd)
      ?~  req=(~(get by requested.pool) ship.q.cmd)  ~|(%no-request-outstanding !!)
      ?^  q.u.req  ~|(%request-already-determined !!)
      :: update requested and add to members
      ::
      =.  requested.pool  (~(put by requested.pool) ship.q.cmd [now.bowl `&])
      =.  members.pool    (~(put in members.pool) ship.q.cmd)
      :_  this(pools (~(put by pools) p.cmd pool))
      =/  =path  /pool/(scot %p host.p.cmd)/[name.p.cmd]
      :~
        :: send accept gesture
        ::
        =/  =cage  pools-request-gesture+!>([p.cmd %accept])
        [%pass / %agent [ship.q.cmd dap.bowl] %poke cage]
        :: send %requested update
        ::
        =/  upd=pool-update  [%requested %& ship.q.cmd [now.bowl `&]]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
        :: send %member update
        ::
        =/  upd=pool-update  [%member %& ship.q.cmd]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
      ==
      ::
        %reject
      :: only the host can accept/reject requests
      ::
      ?>  =(our.bowl host.p.cmd)
      :: cannot reject non-existent or already-determined request
      ::
      =/  =pool           (~(got by pools) p.cmd)
      ?~  req=(~(get by requested.pool) ship.q.cmd)  ~|(%no-request-outstanding !!)
      ?^  q.u.req  ~|(%request-already-determined !!)
      :: update requested
      ::
      =.  requested.pool  (~(put by requested.pool) ship.q.cmd [now.bowl `|])
      :_  this(pools (~(put by pools) p.cmd pool))
      :~
        :: send reject gesture
        ::
        =/  =cage  pools-request-gesture+!>([p.cmd %reject])
        [%pass / %agent [ship.q.cmd dap.bowl] %poke cage]
        :: send %requested update
        ::
        =/  =path  /pool/(scot %p host.p.cmd)/[name.p.cmd]
        =/  upd=pool-update  [%requested %& ship.q.cmd [now.bowl `|]]
        [%give %fact ~[path] pools-pool-update+!>(upd)]
      ==
    ==
    ::
      %pools-invite-gesture
    =/  ges=invite-gesture  !<(invite-gesture vase)
    ?-    q.ges
        %invite
      :: only the host can invite
      ::
      ?>  =(src.bowl host.p.ges)
      :: add to invites
      ::
      :_  this(invites (~(put by invites) p.ges [now.bowl ~]))
      :: send home update
      ::
      =/  upd=home-update  [%invite %& p.ges [now.bowl ~]]
      [%give %fact ~[/home] pools-home-update+!>(upd)]~
      ::
        %cancel
      :: only the host can invite
      ::
      ?>  =(src.bowl host.p.ges)
      :: remove from invites
      ::
      :_  this(invites (~(del by invites) p.ges))
      :: send home update
      ::
      =/  upd=home-update  [%invite %| p.ges]
      [%give %fact ~[/home] pools-home-update+!>(upd)]~
      ::
        %accept
      :: update invited and add to members
      ::
      =/  invitee=ship  src.bowl
      =/  =pool  (~(got by pools) p.ges)
      ?>  (~(has by invited.pool) invitee)
      =.  invited.pool
        (~(put by invited.pool) invitee [now.bowl `&])
      =.  members.pool  (~(put in members.pool) invitee)
      :_  this(pools (~(put by pools) p.ges pool))
      :: send %invited update
      ::
      =/  =path  /pool/(scot %p host.p.ges)/[name.p.ges]
      =/  upd=pool-update  [%invited %& invitee [now.bowl `&]]
      [%give %fact ~[path] pools-pool-update+!>(upd)]~
      ::
        %reject
      :: update invited
      ::
      =/  invitee=ship  src.bowl
      =/  =pool  (~(got by pools) p.ges)
      ?>  (~(has by invited.pool) invitee)
      =.  invited.pool
        (~(put by invited.pool) invitee [now.bowl `|])
      :_  this(pools (~(put by pools) p.ges pool))
      :: send %invited update
      ::
      =/  =path  /pool/(scot %p host.p.ges)/[name.p.ges]
      =/  upd=pool-update  [%invited %& invitee [now.bowl `|]]
      [%give %fact ~[path] pools-pool-update+!>(upd)]~
    ==
    ::
      %pools-request-gesture
    =/  ges=request-gesture  !<(request-gesture vase)
    ?-    q.ges
        %request
      :: add to requested
      ::
      =/  requester=ship  src.bowl
      =/  =pool  (~(got by pools) p.ges)
      =.  requested.pool
        (~(put by requested.pool) requester [now.bowl ~])
      :_  this(pools (~(put by pools) p.ges pool))
      %+  welp
        :: send %requested update
        ::
        =/  =path  /pool/(scot %p host.p.ges)/[name.p.ges]
        =/  upd=pool-update  [%requested %& requester [now.bowl ~]]
        [%give %fact ~[path] pools-pool-update+!>(upd)]~
      :: auto-accept or auto-deny
      :: 
      ?+    (get-auto:hc requester graylist.pool)  ~
          [~ %&]
        =/  =cage  pools-request-command+!>([p.ges %accept requester])
        [%pass / %agent [our dap]:bowl %poke cage]~
          [~ %|]
        =/  =cage  pools-request-command+!>([p.ges %reject requester])
        [%pass / %agent [our dap]:bowl %poke cage]~
      ==
      ::
        %cancel
      :: remove from requested
      ::
      =/  requester=ship  src.bowl
      =/  =pool  (~(got by pools) p.ges)
      =.  requested.pool  (~(del by requested.pool) requester)
      :_  this(pools (~(put by pools) p.ges pool))
      :: send %requested update
      ::
      =/  =path  /pool/(scot %p host.p.ges)/[name.p.ges]
      =/  upd=pool-update  [%requested %| requester]
      [%give %fact ~[path] pools-pool-update+!>(upd)]~
      ::
        %accept
      :: only the host can accept/reject requests
      ::
      ?>  =(src.bowl host.p.ges)
      :: update requests
      ::
      ?>  (~(has by requests) p.ges)
      :_  this(requests (~(put by requests) p.ges [now.bowl `&]))
      :~
        :: send home update
        ::
        =/  upd=home-update  [%request %& p.ges [now.bowl `&]]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        :: watch pool path
        ::
        =/  =wire  /pool/(scot %p host.p.ges)/[name.p.ges]
        [%pass wire %agent [src dap]:bowl %watch wire]
      ==
      ::
        %reject
      :: only the host can accept/reject requests
      ::
      ?>  =(src.bowl host.p.ges)
      :: update requests
      ::
      ?>  (~(has by requests) p.ges)
      :_  this(requests (~(put by requests) p.ges [now.bowl `|]))
      :: send home update
      ::
      =/  upd=home-update  [%request %& p.ges [now.bowl `|]]
      [%give %fact ~[/home] pools-home-update+!>(upd)]~
    ==
  ==
::
++  on-watch
  |=  =(pole knot)
  ^-  (quip card _this)
  ?+    pole  (on-watch:def pole)
    [%vent @ @ ~]  `this
    [%home ~]      `this
    :: sends updates on sent requests, request receipts,
    :: received invites and 
    ::
      [%pool h=@ n=@ ~]
    =/  host=ship  (slav %p h.pole)
    ?>  =(host our.bowl)
    =/  =id        [host n.pole]
    :: use of gut prevents a watcher from knowing
    :: whether the pool actually exists or not
    :: based only on a stack trace
    ::
    =/  =pool      (~(gut by pools) id *pool)
    ?>  (~(has in members.pool) src.bowl)
    :: give initial update
    ::
    :_(this [%give %fact ~[pole] pools-pool-update+!>([%pool pool])]~)
  ==
::
++  on-leave
  |=  =(pole knot)
  ?+    pole  (on-leave:def pole)
      [%pool h=@ n=@ ~]
    =/  host=ship     (slav %p h.pole)
    ?<  =(host src.bowl) :: for good measure
    =/  =id           [host n.pole]
    =/  =pool         (~(got by pools) id)
    :: remove from members, invited, requested and receipts
    ::
    =.  members.pool    (~(del in members.pool) src.bowl)
    =.  invited.pool    (~(del by invited.pool) src.bowl)
    =.  requested.pool  (~(del by requested.pool) src.bowl)
    =.  receipts.pool   (~(del by receipts.pool) src.bowl)
    :_  this(pools (~(put by pools) id pool))
    :~
      :: send %member update
      ::
      =/  upd=pool-update  [%member %| src.bowl]
      [%give %fact ~[pole] pools-pool-update+!>(upd)]
      :: send %invited update
      ::
      =/  upd=pool-update  [%invited %| src.bowl]
      [%give %fact ~[pole] pools-pool-update+!>(upd)]
      :: send %requested update
      ::
      =/  upd=pool-update  [%requested %| src.bowl]
      [%give %fact ~[pole] pools-pool-update+!>(upd)]
      :: send %receipt update
      ::
      =/  upd=pool-update  [%receipt %| src.bowl]
      [%give %fact ~[pole] pools-pool-update+!>(upd)]
    ==
  ==
::
:: TODO: make state externally legible
++  on-peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+    pole  (on-peek:def pole)
    [%x %pools ~]     ``pools-peek+!>(pools+pools)
    [%x %invites ~]   ``pools-peek+!>(invites+invites)
    [%x %requests ~]  ``pools-peek+!>(requests+requests)
    [%x %receipts ~]  ``pools-peek+!>(receipts+receipts)
      [%x %pool h=@ n=@ ~]
    =/  host=ship  (slav %p h.pole)
    =/  =id        [host n.pole]
    ``pools-peek+!>(pool+(~(got by pools) id))
  ==
::
++  on-agent
  |=  [=(pole knot) =sign:agent:gall]
  ^-  (quip card _this)
  ?+    pole  (on-agent:def pole sign)
      [%pool h=@ n=@ ~]
    =/  host=ship  (slav %p h.pole)
    ?>  =(host src.bowl)
    =/  =id        [host n.pole]
    ?+    -.sign  (on-agent:def pole sign)
        %watch-ack
      ?~  p.sign
        :_(this [%give %fact ~[/home] pools-home-update+!>([%pool %& id])]~)
      %-  (slog 'Subscribe failure.' ~)
      %-  (slog u.p.sign)
      :: clear pool from state on watch nack
      ::
      :_  %=  this
            pools     (~(del by pools) id)
            invites   (~(del by invites) id)
            requests  (~(del by requests) id)
            receipts  (~(del by receipts) id)
          ==
      :~
        :: send home updates
        ::
        =/  upd=home-update  [%pool %| id]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        =/  upd=home-update  [%invite %| id]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        =/  upd=home-update  [%request %| id]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
        =/  upd=home-update  [%receipt %| id]
        [%give %fact ~[/home] pools-home-update+!>(upd)]
      ==
      ::
        %kick
      :: resubscribe on kick
      ::
      %-  (slog '%pools: Got kick, resubscribing...' ~)
      :_(this [%pass pole %agent [src dap]:bowl %watch pole]~)
      ::
        %fact
      ?.  =(p.cage.sign %pools-pool-update)  (on-agent:def pole sign)
      :: incorporate pool update
      ::
      =/  upd=pool-update  !<(pool-update q.cage.sign)
      =/  =pool  (~(gut by pools) id *pool)
      =.  pool   (do-update:hc upd pool)
      `this(pools (~(put by pools) id pool))
    ==
    ::
      [%invite h=@ n=@ ~]
    ?.  ?=(%poke-ack -.sign)  ~|([%unexpected-agent-sign pole -.sign] !!)
    =/  host=ship  (slav %p h.pole)
    ?>  =(host our.bowl)
    =/  =id        [host n.pole]
    =/  =pool      (~(got by pools) id)
    =/  =path      [%pool +.pole]
    ?.  (~(has by invited.pool) src.bowl)  ~|(%invitee-not-invited !!)
    :: register invite poke-ack
    ::
    :: TODO: send receipts update
    =/  receipt  [src.bowl now.bowl ?=(~ p.sign)]
    =.  receipts.pool  (~(put by receipts.pool) receipt)
    ~?  ?=(^ p.sign)  invite-failure+[id+id ship+src.bowl] :: print nack
    :_  this(pools (~(put by pools) id pool))
    [%give %fact ~[path] pools-pool-update+!>([%receipt %& receipt])]~
    ::
      [%request h=@ n=@ ~]
    ?.  ?=(%poke-ack -.sign)  ~|([%unexpected-agent-sign pole -.sign] !!)
    =/  host=ship  (slav %p h.pole)
    ?<  =(host our.bowl) :: for good measure
    =/  =id        [host n.pole]
    :: register request poke-ack
    ::
    ~?  ?=(^ p.sign)  request-failure+id :: print nack
    :_  this(receipts (~(put by receipts) id now.bowl ?=(~ p.sign)))
    :: send home update
    ::
    =/  upd=home-update  [%receipt %& id [now.bowl ?=(~ p.sign)]]
    [%give %fact ~[/home] pools-home-update+!>(upd)]~
    ::
      [%accept-invite h=@ n=@ ~]
    ?.  ?=(%poke-ack -.sign)  ~|([%unexpected-agent-sign pole -.sign] !!)
    =/  host=ship  (slav %p h.pole)
    ?>  =(host src.bowl)
    =/  =id        [host n.pole]
    ?.  (~(has by invites) id)  ~|(%not-invited-to-pool !!)
    ?^  p.sign  (on-agent:def pole sign)
    :: update invites
    ::
    :_  this(invites (~(put by invites) id [now.bowl `&]))
    :~
      :: send home update
      ::
      =/  upd=home-update  [%invite %& id [now.bowl `&]]
      [%give %fact ~[/home] pools-home-update+!>(upd)]
      :: watch pool path
      ::
      =/  wire  [%pool +.pole]
      [%pass wire %agent [src dap]:bowl %watch wire]
    ==
    ::
      [%reject-invite h=@ n=@ ~]
    ?.  ?=(%poke-ack -.sign)  ~|([%unexpected-agent-sign pole -.sign] !!)
    =/  host=ship  (slav %p h.pole)
    ?>  =(host src.bowl)
    =/  =id        [host n.pole]
    ?.  (~(has by invites) id)  ~|(%not-invited-to-pool !!)
    ?^  p.sign  (on-agent:def pole sign)
    :: update invites
    ::
    :_  this(invites (~(put by invites) id [now.bowl `|]))
    :: send home update
    ::
    =/  upd=home-update  [%invite %& id [now.bowl `|]]
    [%give %fact ~[/home] pools-home-update+!>(upd)]~
  ==
::
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
|_  [=bowl:gall cards=(list card)]
+*  core  .
    io    ~(. agentio bowl)
++  abet  [(flop cards) state]
++  emit  |=(=card core(cards [card cards]))
++  emil  |=(cadz=(list card) core(cards (weld cadz cards)))
::
++  get-auto
  |=  [requester=ship graylist]
  ^-  (unit ?)
  ?^  auto=(~(get by ship) requester)  auto
  ?^  auto=(~(get by rank) (clan:title requester))  auto
  rest
::
++  unique-id
  |=  name=@t
  |^  `id`(uniquify (tasify name))
  ++  uniquify
    |=  =term
    ^-  id
    ?.  (~(has by pools) [our.bowl term])
      [our.bowl term]
    =/  num=@t  (numb (end 4 eny.bowl))
    $(term (rap 3 term '-' num ~)) :: add random number to end
  ++  numb :: from numb:enjs:format
    |=  a=@u
    ?:  =(0 a)  '0'
    %-  crip
    %-  flop
    |-  ^-  ^tape
    ?:(=(0 a) ~ [(add '0' (mod a 10)) $(a (div a 10))])
  ++  tasify
    |=  name=@t
    ^-  term
    =/  =tape
      %+  turn  (cass (trip name))
      |=(=@t `@t`?~(c=(rush t ;~(pose nud low)) '-' u.c))
    =/  =term
      ?~  tape  %$
      ?^  f=(rush i.tape low)
        (crip tape)
      (crip ['x' '-' tape])
    ?>(((sane %tas) term) term)
  --
::
++  do-updates
  |=  [=pool fields=(list field)]
  ^+  pool
  |-  ?~  fields  pool
  %=  $
    fields  t.fields
    pool    (do-update i.fields pool)
  ==
::
++  do-update
  |=  [upd=pool-update =pool]
  ?-    -.upd
    %graylist  pool(graylist graylist.upd)
    %dudes     pool(dudes dudes.upd)
    %pool      pool.upd
      %member
    ?-  -.p.upd
      %&  pool(members (~(put in members.pool) p.p.upd))
      %|  pool(members (~(del in members.pool) p.p.upd))
    ==
      %invited
    ?-  -.p.upd
      %&  pool(invited (~(put by invited.pool) p.p.upd))
      %|  pool(invited (~(del by invited.pool) p.p.upd))
    ==
      %requested
    ?-  -.p.upd
      %&  pool(requested (~(put by requested.pool) p.p.upd))
      %|  pool(requested (~(del by requested.pool) p.p.upd))
    ==
      %receipt
    ?-  -.p.upd
      %&  pool(receipts (~(put by receipts.pool) p.p.upd))
      %|  pool(receipts (~(del by receipts.pool) p.p.upd))
    ==
  ==
--
