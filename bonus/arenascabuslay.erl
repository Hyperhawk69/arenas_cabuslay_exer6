%Arenas, Angelo Gabriel
%Cabuslay, Ryan Vincent
%T-1L

%To run:
%1. init_server() on a terminal
%2. Open other terminals for each chat node
%3. In the other terminals, init_chat(Server_Node)

-module(arenascabuslay).
-compile(export_all).

init_server() -> %starts the server that will hold a list of nodes that are logged in
    register(messenger, spawn(arenascabuslay, server, [[]])).

server(User_List) -> %holds a list of nodes that are logged in and sends messages to other nodes
    receive
        {Chat_Pid, From, Node_Name, logon} -> %appends a node to the list if logged in
       	    io:format("~s logged in~n", [Node_Name]),
            New_User_List = server_logon(Chat_Pid, From, User_List),
            server(New_User_List);

        {Node_Name, Node_Message, Sender_Pid} -> %sends a message to all other nodes
        	io:format("~s sent a message~n", [Node_Name]),
        	send_message(User_List, Node_Name, Node_Message, Sender_Pid),
        	if
				Node_Message=="bye" ->

					init:stop(),%STOP SERVER NODE
					io:format("~s has disconnected~n",[Node_Name]);	


				true -> ok %Don't need to do anything if false
			end,
        	server(User_List)
    end.

server_logon(Chat_Pid, From, User_List) -> %add node to the list
    [{Chat_Pid,From} | User_List]. %list is composed of tuples of each nodeInbox paied with self() id

send_message([Head|Tail], Node_Name, Node_Message, Sender_Pid) ->  %Head is the current node, Tail is the rest of the list
	{_,Y} = Head, %Y is the receiver self() id (From)
	if
		Y /= Sender_Pid -> %if the receiver is not the sender
			{X,_} = Head, %X is the nodeInbox (Chat_Pid)
			X ! {Node_Name, Node_Message}; %send a message to the nodeInbox of the receiver
		true -> ok %else do nothing
	end,
	if 
		Tail /= [] -> send_message(Tail, Node_Name, Node_Message, Sender_Pid); %recurses through the list until the Tail is empty
		true -> ok
	end.

init_chat(Server_Node) ->
	Name=string:chomp(io:get_line("Enter name: ")),
	Chat_Pid = spawn(arenascabuslay,nodeInbox,[]), %Spawn inbox of Node

	{messenger, Server_Node} ! {Chat_Pid, self(), Name, logon}, %node will pass its nodeInbox to the server

	node(Server_Node, Name, Chat_Pid). 


node(Server_Node, Name, Chat_Pid) ->
	Message = string:chomp(io:get_line("You: ")),
	{messenger, Server_Node} ! {Name, Message, self()}, %sends a message to the server to be distributed to others
	if
		Message=="bye" ->
			io:format("You have disconnected~n"),
			init:stop();
		true -> 
			node(Server_Node, Name, Chat_Pid) % Don't need to do anything if false
	end.

nodeInbox() -> %All nodes have one instance of this used to receive messages and print from the other nodes
	receive 
		{Node_Name, Node_Message} ->
			io:format("~s: ",[Node_Name]),%print from node
			io:format("~s ~n",[Node_Message]),
			if
				Node_Message=="bye" ->

					init:stop(),%STOP RECEIVER NODE
					io:format("~s has disconnected~n",[Node_Name]);	


				true -> ok %Don't need to do anything if false
			end
	end,
	nodeInbox().