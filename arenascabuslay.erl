-module(arenascabuslay).
-compile(export_all).

chat_init() ->
	% String = io:get_line ("Enter your name: "),
	% Name = string:trim(String, trailing, "\n."),
	register(nodeInbox1,spawn(arenascabuslay,nodeInbox,[])),%Node1 inbox
	register(node1,spawn(arenascabuslay,node1,["Jim", empty, empty])).%Spawn node1 with empty parameters

node1(Name, Node2_Name, Chat_Pid)->
	if
		Node2_Name==empty -> %Not yet received Node2_Name or inbox Pid, so do nothing
			io:format("You have logged in~n"),
			Message_Init=empty;
		true -> %Received node2 inbox, can send messages now
			Message_Init = io:get_line ("You: "),
			Chat_Pid ! {Name, Message_Init, self(), {node2,Node2_Name} },
				if
					Message_Init=="bye" ->
						% io:format("~s ~n", [Node2_Name]),

						Node2_Name ! quit, %Doesn't work

						io:format("You have disconnected~n"),
						init:stop();
					true -> 
						node1(Name, Node2_Name,Chat_Pid)
				end	
	end,


	receive
		{Node2_Name_Initial, Chat_Pid_Initial} ->%Receive the Node2 inbox and name
			io:format("Received~n"),
			node1(Name, Node2_Name_Initial,Chat_Pid_Initial);
			
		quit -> %if receive quit from node2, disconnect
			init:stop(),
			io:format("node1 Your partner has disconnected~n")
		
	end.

nodeInbox() -> %Both nodes have one instance of this used to receive messages and print from the other node
	receive 
		{Node_Name, Node_Message,Sender_Pid,Receiver_Pid} ->
			io:format("[Chat] ~s: ",[Node_Name]),%print from node1
			io:format("~s ~n",[Node_Message]),
			if
				Node_Message=="bye" ->
					Receiver_Pid ! quit,
					io:format("~s has disconnected~n",[Node_Name]);	
				true -> ok %Don't need to do anything if false
			end
	end,
nodeInbox().




chat_init2(Node1_Node) ->
	Name2="Jimmy",
	Chat_Pid = spawn(arenascabuslay,nodeInbox,[]), %Spawn inbox of Node2
	{node1, Node1_Node} ! {self(),Chat_Pid}, %Send node1 the inbox of Node2
	
	node2(Name2, Node1_Node,Chat_Pid). %If I use this instead of ^ spawn, it works? Ba't ganun


node2(Name2,Node1_Node,Chat_Pid) ->
	Message = string:chomp(io:get_line("Input: ")),
	{nodeInbox1,Node1_Node} ! {Name2, Message,self(),{node1, Node1_Node}}, % Send message to other node
	if
		Message=="bye" ->
			io:format("You have disconnected~n"),
			{node1,Node1_Node} ! quit, % < Doesn't work, this needs to work so node1 will terminate
			init:stop();
		true -> 
			node2(Name2,Node1_Node,Chat_Pid) % Don't need to do anything if false
	end,
	
	receive
		quit ->
			init:stop(),
			io:format("Your partner has disconnected~n")
	end.
