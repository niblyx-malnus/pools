# %pools
A minimal "pool" membership manager. A "pool" is a set of ships managed by a host.

Heavily inspired by %pals.

Many applications need to manage groups of people and need to be able to send, cancel, accept, and reject invitations and requests for entry to the group, to be able to kick members and to allow members to leave.

An ecosystem of composable apps would benefit from a minimal and clear %pals-sized agent specialized for this purpose.

By delegating responsibility for role management (apart from host/member), metadata, visibility/discovery and invite/request messages to the client app and restricting all actions on the pool to the host ship %pools becomes a very compact and general tool.
