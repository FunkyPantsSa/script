#用python启动一个占用端口的程序，用于测试端口访问是否畅通

import socket

def start_server(host, port):
    # 创建一个TCP/IP socket
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    # 绑定socket到指定的地址和端口
    server_address = (host, port)
    print("Starting server on {}:{}".format(server_address[0], server_address[1]))
    server_socket.bind(server_address)
    
    # 监听连接
    server_socket.listen(1)
    print("Listening on port {}. Waiting for a connection...".format(port))

    while True:
        # 接受连接
        connection, client_address = server_socket.accept()
        try:
            print("Connection from", client_address)
            # 接收数据
            while True:
                data = connection.recv(16)
                if data:
                    print("Received:", data)
                    # 响应客户端
                    connection.sendall(data)
                else:
                    break
        finally:
            # 清理连接
            connection.close()

if __name__ == "__main__":
    HOST = '0.0.0.0'  # 监听所有接口
    PORT = 12345      # 要占用的端口

    try:
        start_server(HOST, PORT)
    except KeyboardInterrupt:
        print("\nServer is shutting down.")
    except Exception as e:
        print("Error:", e)