#!/usr/bin/env swipl

%:- set_prolog_flag(verbose, silent).
%:- initialization mumblemainusers.

:- dynamic channel/2.
:- dynamic parent/2.
:- dynamic user/2.
:- dynamic in/2.
:- dynamic afk/1.
:- dynamic bot/1.
:- dynamic restr/1.

:- use_module(library(http/http_open)).
:- use_module(library(http/json)).

:- consult('config.prolog').
% In reassigned.prolog you may define username overrides for certain user IDs.
% This is only used for displaying.
% These configurations have the form:  reassigned_username(UserID, "NEW NAME").
% Exmaple:                             reassigned_username(1, "Gordon Freeman").
:- dynamic reassigned_username/2.
%:- consult('reassigned.prolog').

standalonecount :-
    mumblemain(Relevant),
    length(Relevant, Count),
    writeln(Count),
    halt.

standaloneusers :-
  standaloneusers2,
  halt.

standaloneusers2 :-
  mumblemain(Relevant),
  length(Relevant, Count),
  (Count > 0) -> (
    writeln("Relevant Users:"),
    maplist(printuser, Relevant)
  ) ; true.


mumblemain(RelevantUsers2) :-

  retractall(channel(_,_)),
  retractall(parent(_,_)),
  retractall(user(_,_)),
  retractall(in(_,_)),
  retractall(afk(_)),
  retractall(bot(_)),
  retractall(restr(_)),

  cvpURL(CVP_URL),
  http_open(CVP_URL, InStream, []),
  %open('samplejson.json', read, InStream, []), % testing
  json_read_dict(InStream, JsonDict),
  close(InStream),

  % search channels from Root level on
  scanall(JsonDict.root),
  % gather all user IDs
  findall(Id, user(Id,_Name), Users),
  % exclude unregistered, bots, AFKler, restricted, my accounts...
  excludeT([unregistered, bot, afk, inRestrictedChannel, ignoreme], Users, RelevantUsers),
  % expand user IDs to useful entries
  maplist(expand, RelevantUsers, RelevantUsers2).


excludeT([], L, L).
excludeT([H|T], L1, L3) :- exclude(H, L1, L2), excludeT(T, L2, L3).


unregistered(-1).
inRestrictedChannel(Id) :- in(Id, Cid), restr(Cid).
ignoreme(Id) :- user(Id, Name), myself(Name). % nicknames are whitelisted


expand(Id, Channel-Name) :-
  (reassigned_username(Id, Name) ; user(Id, Name)),
  in(Id, Cid), channel(Cid, Channel).


scanall(Root) :-
  channels(Root),
  findall(Id, channel(Id, _Name), Channels),
  maplist(restrictedCheck, Channels).

restrictedCheck(Id) :-
  restrictedChannel(Id) -> assert(restr(Id)) ; true.

% channels(JsonChannel)/1
channels([], []).
channels(C) :-
  maplist(user, C.users),
  maplist(channels, C.channels),
  assert(channel(C.id, C.name)),
  assert(parent(C.id, C.parent)).

% user(JsonUser)/1
user(U) :-
  assert(user(U.userid, U.name)),
  assert(in(U.userid, U.channel)),
  (afkCheck(U) -> assert(afk(U.userid)) ; true),
  (botCheck(U) -> assert(bot(U.userid)) ; true).

afkCheck(JsonUser) :-
  JsonUser.suppress; % true if channel suppresses the user
  JsonUser.selfMute; % selbst stummgestellt
  JsonUser.selfDeaf; % selbst taubgestellt
  JsonUser.mute;
  JsonUser.deaf.

botCheck(JsonUser) :-
  JsonUser.name = "fluffy";
  string_lower(JsonUser.name, LCname),
  sub_string(LCname, _Before, _Length, _After, "bot").

restrictedChannel(Id) :-
  %channel(Id, Name), melt(['----checking restrictedChannel for ', Name]),
  subof(Id, Name),
  restricted(Name).

% subof(ChannelID, NameOfUpperChannel)/2

subof(Id, Name) :-
  channel(Id, Name).

subof(Id, UpperName) :-
  channel(UpperId, UpperName),
  parentT(Id, UpperId).

% transitive parent
parentT(X, Y) :- parent(X, Y).
parentT(X, Z) :- parent(X, Y), parentT(Y, Z).

printuser(Chan-User) :-
  ppprint(["    ", Chan, " - ", User]).

ppprint(ListOfStrings) :-
  reverse(ListOfStrings, Reversed),
  foldl(string_concat, Reversed, "", Result),
  writeln(Result).
