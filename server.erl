-module(server).
-behaviour(gen_server).
-import(mod_esi, [deliver/2]).

-export([start/0, start_link/0]).
-export([req_new_player/3, json_read_table/3, json_get_state/3, json_make_move/3, json_get_players/3]).

-export([test/3, test1/3, test_cast/3, test_out/3]).
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).
-define(LINK, {global, ?SERVER}).
-define(FILE_NAME, "names").
-define(FILE_NAME_TABLE, "table_cells").
-define(MOVE_NAME, "moves").
-define(Header,"Content-Type: application/json\r\n\r\n").
-define(TABLE_SIZE_X, 30).
-define(TABLE_SIZE_Y, 30).
-define(SIZE_OF_TABLE, (?TABLE_SIZE_X+4)*(?TABLE_SIZE_Y+4)).

handle_cast(_Request, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.


start() -> start_link().

start_link() -> io:format("Started"), gen_server:start_link(?LINK, ?MODULE, [], []).

init([]) -> io:format("~nALL WILL BE OK~n"),
    open_file_names(),
    open_file_table(),
    open_file_moves(),
    init_table(?SIZE_OF_TABLE),
    {ok, "My Server Working"}.

open_file_names() ->
  try
      dets:open_file('players', [{file, ?FILE_NAME}, {auto_save, 1000}, {type, bag}]),
      dets:delete_all_objects('players')
  catch
     Cls:Msg ->
       io:format("Can't open PLAYERS file: ~s : ~s~n", [Cls, Msg]),
       {error, dberr}
  end.
open_file_table() ->
  try
    dets:open_file('table', [{file, ?FILE_NAME_TABLE}, {auto_save, 1000}, {type, bag}]),
    dets:delete_all_objects('table')
  catch
    Cls:Msg ->
      io:format("Can't open TABLE file: ~s : ~s~n", [Cls, Msg]),
      {error, dberr}
  end.
open_file_moves() ->
  try
    dets:open_file('moves', [{file, ?MOVE_NAME}, {auto_save, 1000}, {type, bag}]),
    dets:delete_all_objects('moves'),
    dets:insert('moves',{1})
  catch
    Cls:Msg ->
      io:format("Can't open MOVES file: ~s : ~s~n", [Cls, Msg]),
      {error, dberr}
  end.


read_table1(Ind)->

  if
    Ind == '$end_of_table' -> "";
    true->
      Next = dets:next('table',Ind),
      if
        Next == '$end_of_table' -> ["\""++integer_to_list(Ind)++"\":\""++ integer_to_list(element(2,element(1, list_to_tuple(dets:lookup('table', Ind)))))++"\""];
        true -> ["\""++integer_to_list(Ind)++"\":\""++ integer_to_list(element(2,element(1, list_to_tuple(dets:lookup('table', Ind)))))++"\","++read_table(dets:next('table',Ind))]
      end
  end.



init_table(Num) ->
  if
    Num>0 -> dets:insert('table',{Num, 0}), init_table(Num-1);
    true -> []
  end.
read_table(Num)->
  if
    Num>1 -> "\""++integer_to_list(Num)++"\" : \""++ integer_to_list(element(2, element(1,list_to_tuple(dets:lookup('table',Num))))) ++"\" , " ++read_table(Num-1);
    Num==1 -> "\""++"1"++"\" : \""++integer_to_list(element(2, element(1,list_to_tuple(dets:lookup('table',1)))))++"\""
  end.
json_read_table(SessionId, _Env, _Input) -> deliver(SessionId, ["{ " ++ gen_server:call(?LINK, {get_table}) ++ "}"]).



init_player(Num, Name) ->
  L = length(dets:lookup('players', Num)),
  if
       Num>5 -> "\"1\"";
       L >0 -> init_player(Num+1, Name);
       true -> dets:insert('players', {Num, Name}),
              "\"0\"," ++ "\"num\": \"" ++integer_to_list(Num)++"\""
  end.

json_get_players(SessionId, _Env, _Input) -> deliver(SessionId, ["{" ++ gen_server:call(?LINK, {get_players})++"}"]).
players_list(Num)->
  if
    Num>0 ->
      My_list = dets:lookup('players', Num),
      if
        length(My_list)>0 ->
            My_tuple = element(1,list_to_tuple(My_list)),
            L = tuple_size(My_tuple),
              if
                L>0 ->
                  if
                    Num>1 ->["\""++integer_to_list(Num)++"\":\""]++tuple_to_list(element(2,My_tuple))++"\","++players_list(Num-1);
                    true -> ["\""++integer_to_list(Num)++"\":\""]++tuple_to_list(element(2,My_tuple))++"\""
                  end;
                true -> ""
              end;
        true -> ["\""++integer_to_list(Num)++"\":\"0\","++ players_list(Num-1)]
      end;
    true -> ""
  end.

parse_player(In) ->
    Request = http_uri:decode(In),
    WordCount = string:words(Request, 47),
    if
      WordCount==1 -> {string:sub_word(Request, 1, 47)};
      true -> "\"2\""
    end.
req_new_player(SessionId, _Env, _Input) ->
    deliver(SessionId, [ "{ "++"\"Exit_code\":"++ gen_server:call(?LINK, {new_player, parse_player(_Input)})++ "}"]).


json_get_state(SessionId, _Env, _Input) -> deliver(SessionId, gen_server:call(?LINK,{get_state})).
server_get_state() ->
  I = dets:first('moves'),
  if
    I>0-> "{ \"State\": \""++integer_to_list(I)++"\" }";
    true -> "{ \"State\":\"0\" , \"Winner\": \""++integer_to_list(dets:next('moves',0))++"\" }"
  end.


parse_move(In)->
  Request = http_uri:decode(In),
  WordCount = string:words(Request, 47),
  if
    WordCount==2 -> { list_to_integer(string:sub_word(Request, 1, 47)), list_to_integer(string:sub_word(Request, 2, 47))};
    true -> ""
  end.
json_make_move(SessionId, _Env, Input) -> deliver(SessionId, gen_server:call(?LINK, {make_move , parse_move(Input)})).
server_make_move(Num, Cell)->
  S = dets:first('moves'),  % WHO SHOULD MAKE MOVE
  if
    Num==S ->   % Num - WHO WANT MAKE MOVE
      %Table_cell_num = tuple_size(list_to_tuple(C)),
      C = dets:lookup('table',Cell),
      Table_cell_num = element(2,element(1,list_to_tuple(C))),
      if
        Table_cell_num==0 ->
          %dets:insert('table', {Cell, Num}),
          Flag = not check_table(Num, Cell),

          dets:delete('table', Cell),
          dets:insert('table', {Cell, Num}),
          if
           Flag=='true' ->
              dets:delete('moves', Num),
              dets:insert('moves', {(Num rem (dets:info('players',no_objects)))+1 }),
              "{ \"Result\" :\"ok\" }";
           true ->
              dets:delete('moves', Num),
              dets:insert('moves', {0}),
              dets:insert('moves', {Num}),
              "{ \"Result\" :\"ok\" }"
          end;
        true -> "{ \"Result\" :\"Not available\" }"
      end;
    true -> "{ \"Result\" :\"Not your turn\"}"
  end.


check_table(Num, Cell) ->
    X = ?TABLE_SIZE_Y+4,
    Y = 1,
    C1= (((el2(Cell+X+Y))==Num) and ((el2(Cell-X-Y))==Num)),
    C2= (((el2(Cell+X-Y))==Num) and ((el2(Cell-X+Y))==Num)),
    C3= (((el2(Cell+X))==Num) and ((el2(Cell-X))==Num)),
    C4= (((el2(Cell+Y))==Num) and ((el2(Cell-Y))==Num)),
    C5= (((el2(Cell+X+Y))==Num) and ((el2(Cell+2*X+2*Y))==Num)),
    C6= (((el2(Cell+X))==Num) and ((el2(Cell+2*X))==Num)),
    C7= (((el2(Cell+X-Y))==Num) and ((el2(Cell+2*X-2*Y))==Num)),
    C8= (((el2(Cell-Y))==Num) and ((el2(Cell-2*Y))==Num)),
    C9= (((el2(Cell-X-Y))==Num) and ((el2(Cell-2*X-2*Y))==Num)),
    C10= (((el2(Cell-X))==Num) and ((el2(Cell-2*X))==Num)),
    C11= (((el2(Cell-X+Y))==Num) and ((el2(Cell-2*X+2*Y))==Num)),
    C12= (((el2(Cell+Y))==Num) and ((el2(Cell+2*Y))==Num)),

    F = C1 or C2 or C3 or C4 or C5 or C6 or C7 or C8 or C9 or C10 or C11 or C12,
    if
      F -> 'true';
      true -> 'false'
    end.
el2(X)-> element(2, element(1, list_to_tuple(dets:lookup('table',X)))).



handle_call({new_player, "Bad arguments"}, _From, State) -> {reply, integer_to_list(0) , State}; %+
handle_call({new_player, Name}, _From, State) -> {reply, init_player(1, Name), State};  %+
%handle_call({get_table}, _From, State) -> {reply, read_table(dets:first('table')), State };  %+
handle_call({get_table}, _From, State) -> {reply, read_table(?SIZE_OF_TABLE), State };  %+
handle_call({get_players}, _From, State) -> {reply, players_list(5), State };
handle_call({get_state}, _From, State) -> {reply, server_get_state() , State}; %+
handle_call({make_move, {Num, Cell}}, _From, State) -> {reply,  server_make_move(Num, Cell),State};
handle_call({test}, _From, State) -> {reply, [], State}.







%
%move(Num, X, Y) ->
%Now = dest:first('moves'),
%  if
%    Now==Num ->  ;
%    true ->
%  end

%test_check(SessionId, _Env, _Input) -> deliver(SessionId,   )


test_out(SessionId, _Env, _Input) -> deliver(SessionId, [read_table(4)]).

test(SessionId, _Env, _Input) ->
  St = gen_server:call(?LINK,{test}),
  Check = is_list(St),
  if
    Check==true -> deliver(SessionId, St);
    true -> deliver(SessionId, "WAS NOT LIST")
  end.

test1(SessionId, _Env, _Input) -> deliver(SessionId, _Input).
%deliver(SessionId, trans(_Input)).

test_cast(SessionId, _Env, _Input) -> deliver(SessionId, [gen_server:cast(?LINK,{call})]).