import socket
import signal
import sys

udp_server_socket = None
tcp_server_socket = None
client_address = None

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
    tcp_server_socket.bind((host, port))
    tcp_server_socket.listen(1)
    print(f"TCP Server listening on {host}:{port}")

    while True:
        client_socket, client_address = tcp_server_socket.accept()
        print(f"Connection from {client_address}")
        while True:
            data = client_socket.recv(1024).decode('utf-8')
            print(f"Received from client: {data}")
            if data=="exit": break

            response = "Pong"
            client_socket.send(response.encode('utf-8'))
            print(f"Sent to client: {response}")

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
        if data:
            with open("socketStream.txt", 'a') as file:
                file.write(data.decode('utf-8'))
        if data.decode('utf-8') == "exit":
            print(f"Closing connection with {client_address}")
            break
    udp_server_socket.close()

if __name__ == "__main__":
    # Register the signal handler for SIGINT (Ctrl+C)
    signal.signal(signal.SIGINT, signal_handler)

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    localIP = s.getsockname()[0]
    s.close()
    start_udp_server(localIP, 65432)
    #start_tcp_server(localIP, 65432)