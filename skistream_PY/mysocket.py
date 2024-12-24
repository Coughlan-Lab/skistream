import socket
import signal
import sys
import json
import sys

udp_server_socket = None
tcp_server_socket = None
client_address = None

# Global storage for chunks
messages = {}

def signal_handler(sig, frame):
    #print("\nCtrl+C intercepted! Cleaning up...")
    if udp_server_socket:
        ack_message = "0".encode('utf-8')
        udp_server_socket.sendto(ack_message, client_address)
        udp_server_socket.close()
        print("UDP server socket closed.")
    if tcp_server_socket:
        tcp_server_socket.close()
        print("TCP server socket closed.")
    sys.exit(0)


def start_tcp_server(host, port):
    global tcp_server_socket
    global client_address
    tcp_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcp_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    tcp_server_socket.bind((host, port))
    tcp_server_socket.listen(1)
    print(f"TCP Server listening on {host}:{port}")

    while True:
        client_socket, client_address = tcp_server_socket.accept()
        print(f"Connection from {client_address}")
        while True:
            data = client_socket.recv(1024).decode('utf-8')

            if len(data) == 1:
                ack_message = "1".encode('utf-8')
                client_socket.send(ack_message)  # Send ACK back to the client
                continue

            if data == "exit":
                print(f"Closing connection with {client_address}")
                break
            
            #print(data)
            # Find the boundary between JSON header and payload
            json_end_index = data.find('}', 70)
            #print("index ", json_end_index)
            if json_end_index == -1:
                print("Invalid data format, no JSON end found.")
                continue

            json_part = data[:json_end_index+1]
            payload_part = data[json_end_index+1:]

            try:
                message = json.loads(json_part)
            except json.JSONDecodeError:
                print("Received data is not a valid JSON.")
                continue

            # Check if it's a valid message with necessary fields
            if 'id' in message and 'totalChunks' in message and 'sequenceNumber' in message:
                msg_id = message['id']
                sequence_number = message['sequenceNumber']
                total_chunks = message['totalChunks']

                if total_chunks==1:
                    print("write 1 chunck message")
                    # Write the complete message to the file
                    complete_message_received(payload_part)
                    continue
                
                # Initialize or append to message storage
                if msg_id not in messages:
                    messages[msg_id] = [None] * total_chunks

                messages[msg_id][sequence_number-1] = payload_part

                # Check if all chunks have been received
                if None not in messages[msg_id]:
                    print("write multiple chunck message")
                    # Reassemble the complete message
                    complete_message = ''.join(messages[msg_id])
                    #call function for entire message
                    complete_message_received(complete_message)
                    # Remove the message from storage after writing
                    del messages[msg_id]

        client_socket.close()

def start_udp_server(host, port):
    global udp_server_socket
    global client_address
    udp_server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_server_socket.bind((host, port))
    print(f"UDP server listening on {host}:{port}")

    while True:
        data, client_address = udp_server_socket.recvfrom(65535)  # Buffer size is 1024 bytes
        print(f"received {len(data)} bytes")
        
        if len(data) == 1:
            ack_message = "1".encode('utf-8')
            udp_server_socket.sendto(ack_message, client_address)  # Send ACK back to the client
            continue
        
        if data.decode('utf-8') == "exit":
            print(f"Closing connection with {client_address}")
            break

        # Convert data to string
        data_str = data.decode('utf-8')
        
        # Find the boundary between JSON header and payload
        json_end_index = data_str.find('}', 70)
        if json_end_index == -1:
            print("Invalid data format, no JSON end found.")
            continue

        json_part = data_str[:json_end_index+1]
        payload_part = data_str[json_end_index+1:]
        
        
        # Write the complete message to the file
        #with open("socketStream2.txt", 'a') as file:
        #    file.write(data_str + '\n')
        
        # Decode the received data
        try:
            message = json.loads(json_part)
        except json.JSONDecodeError:
            print("Received data is not a valid JSON.")
            continue

        # Check if it's a valid message with necessary fields
        if 'id' in message and 'totalChunks' in message and 'sequenceNumber' in message:
            msg_id = message['id']
            sequence_number = message['sequenceNumber']
            total_chunks = message['totalChunks']

            if total_chunks==1:
                # Write the complete message to the file
                #with open("socketStream.txt", 'a') as file:
                #    file.write(payload_part + '\n')
                complete_message_received(payload_part)
                continue
            
            #print(f"receive {msg_id}, chunck {sequence_number} of {total_chunks}")
            # Initialize or append to message storage
            if msg_id not in messages:
                messages[msg_id] = [None] * total_chunks

            messages[msg_id][sequence_number-1] = payload_part

            # Check if all chunks have been received
            if None not in messages[msg_id]:
                # Reassemble the complete message
                complete_message = ''.join(messages[msg_id])
                
                # Write the complete message to the file
                #with open("socketStream.txt", 'a') as file:
                #    file.write(complete_message + '\n')
                #call function for entire message
                complete_message_received(complete_message)
                # Remove the message from storage after writing
                del messages[msg_id]
            #print(f"pending packet to complete: { len(messages)}")
        
        
    udp_server_socket.close()

def complete_message_received(message):
    print("write to file")
    with open("socketStream.txt", 'a') as file:
        file.write(message + '\n')

if __name__ == "__main__":
    # Access individual arguments
    if len(sys.argv) != 2:
        # The first argument passed to the script (after the script name)
        print("launch without argument is illegal, use TCP or UDP")
        exit(1)
    socketType = sys.argv[1]
    if socketType not in ["TCP", "UDP"]:
        print("illegal argument, use TCP or UDP")
        exit(1)
    
    # Register the signal handler for SIGINT (Ctrl+C)
    signal.signal(signal.SIGINT, signal_handler)

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    localIP = s.getsockname()[0]
    s.close()
    if socketType == "TCP":
        start_tcp_server(localIP, 65432)
    elif socketType == "UDP":
        start_udp_server(localIP, 65432)