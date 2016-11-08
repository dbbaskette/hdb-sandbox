import curses
import subprocess
import os

screen = None
HINT_WIDTH = 3
ESCDELAY=25
platform = open("/virtualization").read().strip()


class DHCPMisconfiguration(Exception):
    pass


def make_greet_window():
    versionStr = "HDP "+os.environ.get("HDP_VERSION")+" / HDB "+ os.environ.get("HDB_VERSION")+ "/ Ambari "+ os.environ.get("AMB_VERSION" + " / " + platform)
    H, W = screen.getmaxyx()
    greet_win = screen.subwin(H / 2 - HINT_WIDTH, W, 0, 0)
    greet_win.box()
    greet_win.addstr(1, 2, versionStr )
    greet_win.addstr(2, 2, "http://hortonworks.com     http://pivotal.io/")
    greet_win.addstr(3, 2, "---------------------------------------------")
    greet_win.addstr(4, 2, "username: root      password:  hadoop")
    greet_win.addstr(5, 2, "username: gpadmin   password:  gpadmin")


def make_ip_window():
    H, W = screen.getmaxyx()
    ip_win = screen.subwin(H / 2, W, H / 2 - HINT_WIDTH, 0)
    ip_win.box()
    try:
        import socket
        ip_hosts = socket.gethostbyname(socket.gethostname())

        if platform == "vbox":
            ip = "127.0.0.1"

        elif platform in ["vmware", "hyper-v"]:
            ip = ip_hosts

        if ip_hosts == "127.0.0.1":
	    ip = "localhost"
            #raise DHCPMisconfiguration()
    except DHCPMisconfiguration:
        ip_win.addstr(1, 2, "===================================")
        ip_win.addstr(2, 2, "Connectivity issues detected!")
        ip_win.addstr(3, 2, "===================================")
        ip_win.addstr(4, 2, "Check connection of network interface")
        ip_win.addstr(7, 2, "For details, see VM setup instructions")
    else:
        ip_win.addstr(1, 2, "To initiate your Hortonworks Sandbox session,")
        ip_win.addstr(2, 2, "please open a browser and enter this address ")
        ip_win.addstr(3, 2, "in the browser's address field: ")
        ip_win.addstr(4, 2, "http://%s:8080/" % ip)
        ip_win.addstr(7, 2, "To Launch Apache Zeppelin enter this address in browser:")
        ip_win.addstr(8, 2, "http://%s:9995" % ip)


def make_hint_window():
    H, W = screen.getmaxyx()
    hint_win = screen.subwin(HINT_WIDTH, W, H - HINT_WIDTH, 0)
    hint_win.box()
    if platform == "vmware":
        hint_win.addstr(
            1, 1, "Log in to this virtual machine: Press ESC")
    else:
        hint_win.addstr(
            1, 1, "Log in to this virtual machine: Press ESC")


def init_screen():
    curses.noecho()

    make_greet_window()
    make_ip_window()
    make_hint_window()


def show_netinfo():
    commands = [
        "route -n",
        "getent ahosts",
        "ip addr",
        "cat /etc/resolv.conf",
        "cat /etc/hosts",
    ]

    f = file("/tmp/netinfo", "w")
    for cmd in commands:
        f.write("====  %s ==== \n" % cmd)
        f.write(subprocess.Popen(cmd, shell=True,
                stdout=subprocess.PIPE).communicate()[0])
        f.write("\n")
    f.close()
    subprocess.call("less /tmp/netinfo", shell=True)


def main():
    global screen
    screen = curses.initscr()
    init_screen()

    screen.refresh()

    curses.curs_set(0)

    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "-s":
        screen.getch()
    else:
        while True:
            try:
                c = screen.getch()
                if c == ord('n'):
                    curses.endwin()
                    show_netinfo()
                    screen = curses.initscr()
                    init_screen()
                screen.refresh()
                if c == 27 :
                   curses.endwin()
                   return 0
            except KeyboardInterrupt:
                pass
	curses.endwin()


if __name__ == '__main__':
    main()
