%Arenas, Angelo Gabriel
%Cabuslay, Ryan Vincent
%T-1L

-module(arenascabuslay).
-compile(export_all).

init_chat() ->
	Name = string:chomp(io:get_line("Enter your name: ")),
	register(nodeInbox1,spawn(arenascabuslay,nodeInbox,[])),%Node1 inbox
	register(node1,spawn(arenascabuslay,node1,[Name, empty, empty])).%Spawn node1 with empty parameters

node1(Name, Node2_Name, Chat_Pid)->
	if
		Node2_Name==empty -> %Not yet received Node2_Name or inbox Pid, so do nothing
			io:format("You have logged in~n");
		true -> %Received node2 inbox, can send messages now
			Message_Init = string:chomp(io:get_line ("You: ")),
			Chat_Pid ! {Name, Message_Init},
				if
					Message_Init=="bye" ->
						io:format("You have disconnected~n"),
						init:stop();
					true -> 
						node1(Name, Node2_Name,Chat_Pid)
				end	
	end,


	receive
		{Node2_Name_Initial, Chat_Pid_Initial} ->%Receive the Node2 inbox and name
			io:format("Received~n"),
			node1(Name, Node2_Name_Initial,Chat_Pid_Initial)
		
	end.

nodeInbox() -> %Both nodes have one instance of this used to receive messages and print from the other node
	receive 
		{Node_Name, Node_Message} ->
			io:format("~s: ",[Node_Name]),%print from node1
			io:format("~s ~n",[Node_Message]),
			if
				Node_Message=="bye" ->

					init:stop(),%STOP RECEIVER NODE
					io:format("~s has disconnected~n",[Node_Name]);	


				true -> ok %Don't need to do anything if false
			end
	end,
	nodeInbox().

init_chat2(Node1_Node) ->
	Name2=string:chomp(io:get_line("Enter name: ")),
	Chat_Pid = spawn(arenascabuslay,nodeInbox,[]), %Spawn inbox of Node2
	{node1, Node1_Node} ! {self(),Chat_Pid}, %Send node1 the inbox of Node2

	node2(Name2, Node1_Node,Chat_Pid). 


node2(Name2,Node1_Node,Chat_Pid) ->
	Message = string:chomp(io:get_line("You: ")),
	{nodeInbox1,Node1_Node} ! {Name2, Message}, % Send message to other node
	if
		Message=="bye" ->
			io:format("You have disconnected~n"),
			init:stop();
		true -> 
			node2(Name2,Node1_Node,Chat_Pid) % Don't need to do anything if false
	end.