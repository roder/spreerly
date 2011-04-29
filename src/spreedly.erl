-module(spreedly).
%% -export([create_subscriber/4]).
-compile(export_all).
-define(VERSION, "v4").

create_subscriber(Site, Key, Subscriber) ->
    Body = xmerl:export_simple(Subscriber, xmerl_xml, []),
    {ok, StatusCode, _Headers, ResponseBody} = post(Site, Key, "subscribers.xml", Body),
    case StatusCode of
        "201" -> erlsom:simple_form(ResponseBody);
        _ -> 
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
    end.

update_subscriber(Site, Key, SubscriberID, Subscriber) ->
    Body = xmerl:export_simple(Subscriber, xmerl_xml, []),
    Resource = io_lib:format("subscribers/~s.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = put(Site, Key, Resource, Body), 
    case StatusCode of
        "200" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
   end.

complimentary_subscriptions(Site, Key, SubscriberID, SubscriptionData) ->
    Body = xmerl:export_simple(SubscriptionData, xmerl_xml, []),
    Resource = io_lib:format("subscribers/~s/complimentary_subscriptions.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = post(Site, Key, Resource, Body),
    case StatusCode of
        "201" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
   end.

complimentary_extension(Site, Key, SubscriberID, ExtensionData) ->
    Body = xmerl:export_simple(ExtensionData, xmerl_xml, []),
    Resource = io_lib:format("subscribers/~s/complimentary_time_extension.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = post(Site, Key, Resource, Body),
    case StatusCode of
        "201" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
   end.

complimentary_lifetime(Site, Key, SubscriberID, SubscriptionData) ->
    Body = xmerl:export_simple(SubscriptionData, xmerl_xml, []),
    Resource = io_lib:format("subscribers/~s/lifetime_complimentary_subscriptions.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = post(Site, Key, Resource, Body),
    case StatusCode of
        "201" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
    end.

credit(Site, Key, SubscriberID, Amount) when is_list(Amount) ->
    Body = xmerl:export_simple({"credit",[],[{"amount",[],[Amount]}]}, xmerl_xml, []),
    Resource = io_lib:format("subscribers/~s/credits.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = post(Site, Key, Resource, Body),
    case StatusCode of
        "201" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
    end. 

fee(Site, Key, SubscriberID, FeeData) ->
    Body = xmerl:export_simple(FeeData, xmerl_xml, []),
    Resource = io_lib:format("subscribers/~s/fees.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = post(Site, Key, Resource, Body),
    case StatusCode of
        "201" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
   end. 

stop_auto_renew(Site, Key, SubscriberID) ->
    Resource = io_lib:format("subscribers/~s/stop_auto_renew.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = post(Site, Key, Resource, []),
    case StatusCode of
        "201" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
   end. 

subscription_plans(Site, Key) ->
    {ok, StatusCode, _Headers, ResponseBody} = get(Site, Key, "subscription_plans.xml"),
    case StatusCode of
        "200" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
    end. 

free_trial(Site, Key, SubscriberID, SubscriptionData) ->
    Body = xmerl:export_simple(SubscriptionData, xmerl_xml, []),
    Resource = io_lib:format("subscribers/~s/subscribe_to_free_trial.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = put(Site, Key, Resource, Body), 
    case StatusCode of
        "200" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
   end.

allow_free_trial(Site, Key, SubscriberID) ->
    Resource = io_lib:format("subscribers/~s/allow_free_trial.xml",[SubscriberID]),
    {ok, StatusCode, _Headers, ResponseBody} = put(Site, Key, Resource, []), 
    case StatusCode of
        "200" -> erlsome:simple_form(ResponseBody);
        _ ->
            {error, [{resp_code, StatusCode}, {headers, _Headers}, {body, ResponseBody}]}
   end.

get(Site, Key, Path) ->
  request(Site, Key, Path, get, []).

delete(Site, Key, Path) ->
  request(Site, Key, Path, delete, []).

delete(Site, Key, Path, Body) ->
  request(Site, Key, Path, delete, Body).

post(Site, Key, Path, Body) ->
  request(Site, Key, Path, post, Body).

put(Site, Key, Path, Body) ->
  request(Site, Key, Path, put, Body).

request(Site, Key, Path, Method, Body)
  when is_list(Site), is_list(Key), is_atom(Method) ->
    CaCertFile = filename:join(priv_dir(), "cacert.pem"),
    Options = [{basic_auth, {Key ,"X"}},
               {is_ssl, true},
               {ssl_options, [{verify, verify_type()},
                              {cacertfile, CaCertFile}]
               }],
    URL = io_lib:format("https://spreedly.com/api/~s/~s/~s", [?VERSION, Site, Path]),
    Headers = [{"Content-Type", "application/xml"},
               {"Accept", "application/xml"}],
    ibrowse:send_req(URL, Headers, Method, Body, Options, infinity).

priv_dir() ->
    case code:priv_dir(?MODULE) of
        {error, bad_name} ->
            case code:which(?MODULE) of
                Filename when is_list(Filename) ->
                    filename:join([filename:dirname(Filename),"..", "priv"]);
                _ ->
                    filename:join("..", "priv")
            end;
        Dir ->
            Dir
    end.

verify_type() ->
  {ok, {V,_,_}} = ssl:version(),
  [Result | _ ] = string:tokens(V, "."),
  Version = list_to_integer(Result),
  case Version > 3 of
    true -> verify_peer;
    false -> 2
  end.
