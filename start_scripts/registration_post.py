import os
import pwd, grp
from datetime import datetime

USERINFO_FILE_PATH = os.path.join('/usr/lib/tutorials',
                                  'user_info.dat')
MARKETO_URL = "http://info.hortonworks.com/index.php/leadCapture/save"
CRON_FILE = "/etc/cron.d/1sandbox_registration"
CRON_FILE_ORIGIN = "/usr/lib/hue/tools/start_scripts/registration_post_cron"

LOG_FILE = "/usr/lib/tutorials/registration_post.log"


def do_post():
    with file(LOG_FILE, "a+") as LOG:

        def log(s):
            print >>LOG, "[%s] %s" % (datetime.now().strftime("%d_%m_%Y_%H-%M-%S"), s)
            LOG.flush()

        if os.path.exists(USERINFO_FILE_PATH):
            #DO post
            log("Try to upload...")
            import urllib2

            data = file(USERINFO_FILE_PATH).read()

            request = urllib2.Request(MARKETO_URL)
            request.data = data
            try:
                res = urllib2.urlopen(request)
            except:
                log("Failed to upload.")
            else:
                log("Uploaded successful. Code: %s %s\n%s\n\nheaders: %s" %\
                    (res.code, res.msg, res.read(), res.headers.dict))
                os.rename(USERINFO_FILE_PATH, USERINFO_FILE_PATH + ".posted")

        elif not os.path.exists(USERINFO_FILE_PATH + ".posted"):
            #Not registered yet. Add script to cron
            if not os.path.exists(CRON_FILE):
                with file(CRON_FILE, "w") as f:
                    f.write(file(CRON_FILE_ORIGIN).read())
                log("Script added to cron")

        else:
            #Registered. Remove cron task
            if os.path.exists(CRON_FILE):
                os.remove(CRON_FILE)
            log("Script removed from crontab")

if __name__ == '__main__':
    do_post()
    uid = pwd.getpwnam('hue').pw_uid
    gid = grp.getgrnam('hadoop').gr_gid
    os.chown(LOG_FILE, uid, gid)
