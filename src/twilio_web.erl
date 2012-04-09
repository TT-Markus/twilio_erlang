%%%-------------------------------------------------------------------
%%% @author Ryan Huffman <ryanhuffman@gmail.com>
%%% @copyright 2011, Ryan Huffman
%%% @doc Twilio web server.  Routes requests to handler modules.
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(twilio_web).

-export([start/0, start/1, loop/1, route/2]).

-include("twilio.hrl").

-define(DEFAULT_PORT, 9999).

%% @equiv start(8080)
start() ->
    start(?DEFAULT_PORT).

%% @doc Starts a mochiweb HTTP server on the specified port.  Incoming
%% requests will be routed to the handling "twilio_rt_*" module.
start(Port) ->
    io:format("Starting mochiweb bound to port ~p~n", [Port]),
    mochiweb_http:start([{name, ?MODULE}, {port, Port}, {loop, {?MODULE, loop}}]).

%% @doc Mochiweb loop, handling incoming twilio requests.
loop(Req) ->
    case Req:get(method) of
        'GET' ->
            Params = Req:parse_qs();
        'POST' ->
            Params = Req:parse_post()
    end,
    "/" ++ Path = Req:get(path),
    PathList = string:tokens(Path, "/"),
    % two options here
    % uncomment the first to use Extended TwiML and
    % the inbound_phone subsystem
    % to use this option you will need to break out the state from
    % the path - it will be the last URL segment
    XML = twilio_ext:handle(Params, PathList),

    % uncomment this option to us tradition routing
    %XML = route(PathList, Param),
    Req:ok({"text/xml", XML}).

%% @doc Routes a twilio request to a handler that will
%% return a twiml XML document.
route([Head | PathTail], Params) ->
    HandlerModule = list_to_existing_atom("twilio_rt_" ++ Head),
    Twiml = HandlerModule:handle_request(PathTail, Params),
    twiml:encode(Twiml).

