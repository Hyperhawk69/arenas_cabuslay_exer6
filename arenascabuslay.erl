-module(arenascabuslay).
-compile(export_all).

chat_init() ->
	String = io:get_line ("Enter your name: "),
	Name = string:trim(String, trailing, "\n."),
	register(chatServer1,spawn(arenascabuslay,chatServer,[])),%So Node1 can receive messages
	register(node1, spawn(arenascabuslay,node1,[Name])).

node1(Name) ->
	receive
		{node2, Node2_Pid,Chat_Pid} ->
			Message_Init = string:chomp(io:get_line ("(Node1)You: ")),
			Chat_Pid ! {Name, Message_Init},
			self() ! {node2, Node2_Pid,Chat_Pid},%Send message to self to loop this part
			node1(Name)
	end,
	node1(Name).


chatServer() -> %Both nodes have one instance of this used to receive messages and print from the other node
	receive 
		{Node_Name, Node_Message} ->
			io:format("[Chat] ~s: ",[Node_Name]),%print from node1
			io:format("~s ~n",[Node_Message]);
		{chat2,Name,Message} ->
			io:format("meow. ~n")
	end,

chatServer().


chat_init2(Node1_Node) ->
	String2 = io:get_line ("Enter your name: "),
	Name2 = string:trim(String2, trailing, "\n."),
	Chat_Pid = spawn(arenascabuslay,chatServer,[]), %Allows node2 to accept messages from node1
	spawn(arenascabuslay,node2_init,[Name2,Node1_Node,Chat_Pid]).


node2_init(Name2,Node1_Node,Chat_Pid) ->
	{node1, Node1_Node} ! {node2, self()},
	node2(Name2,Node1_Node,Chat_Pid).

node2(Name2,Node1_Node,Chat_Pid) ->
	{node1, Node1_Node} ! {node2, self(),Chat_Pid},
	self() ! {node2},
	receive
		{node2} ->%receive at the start
			Message = string:chomp(io:get_line ("(Node2) You: ")), %Remove trailing \n
			% Node1_Pid ! {node2, self(), Name2, Message},
			{chatServer1,Node1_Node} ! {Name2, Message},
			self() ! {node2},

			node2(Name2,Node1_Node,Chat_Pid);
		{node1, Node1_Pid, Node_Name, Node_Message} ->
			io:format("Meow~n")
			% io:format("~s: ",[Node_Name]),%printing message from node1
			% io:format("~s ~n",[Node_Message])

			% Message = io:get_line ("You: "),
			% case Message of
			% 	[$b,$y,$e,$\n] -> io:format("Goodbye. ~n");
			% 	_ -> Node1_Pid ! {node2, self(), Name2, Message},
			% 		node2(Name2,Node1_Node)
			% end
	end,
	node2(Name2,Node1_Node,Chat_Pid).