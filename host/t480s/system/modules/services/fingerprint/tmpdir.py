import os
import stat

tmpdir = "/run/python-validity"

directory = os.lstat(tmpdir)
if (
    not stat.S_ISDIR(directory.st_mode)
    or stat.S_IMODE(directory.st_mode) != 0o700
    or directory.st_uid != 0
    or directory.st_gid != 0
):
    raise RuntimeError(f"Refusing unsafe python-validity state directory: {tmpdir}")
