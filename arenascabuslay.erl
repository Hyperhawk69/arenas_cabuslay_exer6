-module(arenascabuslay).
-compile(export_all).

chat_init() ->
	String = io:get_line ("Enter your name: "),
	Name = string:trim(String, trailing, "\n."),
	register(node1, spawn(arenascabuslay,node1,[Name])).

node1(Name) ->
	receive
		{node2, Node2_Pid} ->
			Message_Init = io:get_line ("You: "),
			case Message_Init of
				[$b,$y,$e,$\n] -> io:format("Goodbye. ~n");
				_ -> Node2_Pid ! {node1, self(), Name, Message_Init},
					node1(Name)
			end;
		{node2, Node2_Pid, Node_Name, Node_Message} ->
			io:format("~s: ",[Node_Name]),
			io:format("~s ~n",[Node_Message]),
			Message = io:get_line ("You: "),
			case Message of
				[$b,$y,$e,$\n] -> io:format("Goodbye. ~n");
				_ -> Node2_Pid ! {node1, self(), Name, Message},
					node1(Name)
			end
	end.

chat_init2(Node1_Node) ->
	String2 = io:get_line ("Enter your name: "),
	Name2 = string:trim(String2, trailing, "\n."),
	spawn(arenascabuslay,node2_init,[Name2,Node1_Node]).


node2_init(Name2,Node1_Node) ->
	{node1, Node1_Node} ! {node2, self()},
	node2(Name2,Node1_Node).

node2(Name2,Node1_Node) ->
	receive
		{node1, Node1_Pid, Node_Name, Node_Message} ->
			io:format("~s: ",[Node_Name]),
			io:format("~s ~n",[Node_Message]),
			Message = io:get_line ("You: "),
			case Message of
				[$b,$y,$e,$\n] -> io:format("Goodbye. ~n");
				_ -> Node1_Pid ! {node2, self(), Name2, Message},
					node2(Name2,Node1_Node)
			end
	end.