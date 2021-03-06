-module(handle_server_status).
-behavior(cowboy_handler).

-include("../include/macros/revision.hrl").
-revision(?REVISION).

-author("Chris Whealy <chris.whealy@sap.com>").
-created("Date: 2018/04/03 09:31:24").
-created_by("chris.whealy@sap.com").

-export([init/2]).

%% Records
-include("../include/records/cmd_response.hrl").
-include("../include/records/country_server.hrl").

%% Macros
-include("../include/macros/default_http_response.hrl").

-define(HTTP_GET, <<"GET">>).

%% =====================================================================================================================
%%
%%                                                 P U B L I C   A P I
%%
%% =====================================================================================================================

init(Req=#{method := ?HTTP_GET}, _State) ->
  country_manager ! {cmd, status, self()},

  ServerStatusDetails = receive
    {country_server_list, ServerStatusList, trace_on, Trace} ->
      server_status_details(ServerStatusList, Trace)
  end,

  {ok, cowboy_req:reply(200, ?CONTENT_TYPE_JSON, json:to_bin_string(ServerStatusDetails), Req), _State};


init(Req, _State) ->
  {ok, ?METHOD_NOT_ALLOWED_RESPONSE(Req), _State}.

 
%% =====================================================================================================================
%%
%%                                                P R I V A T E   A P I
%%
%% =====================================================================================================================

%% ---------------------------------------------------------------------------------------------------------------------
%% Format server status list
server_status_details(ServerStatusList, Trace) ->
  CountryManagerTrace = json:property(country_manager_trace, Trace),
  MemoryUsage         = json:property(erlang_memory_usage, format:as_binary_units(erlang:memory(total))),
  JsonArray           = json:array([ json:record_to_json(country_server, S) || S <- ServerStatusList ]),
  Servers             = json:property(servers, JsonArray),

  json:object([CountryManagerTrace, MemoryUsage, Servers]).
