import sys
import os
from pathlib import Path
from mslib import (
    console_logger,
    executors,
    logger,
    level,
    date_time_tag,
    db_connector,
    DatabaseMs,
    PathFinder,
    UpdateMgfOffsetUnit,
)

VERSION = "v1.01"
work_dir = ""
UPLOAD_DIR = "uploaded"
LOCK_FILE_NAME = "MGF_Offset.lock"

db_connection_manager = db_connector.get_database_m_dbwriter()
database_ms = DatabaseMs(db_connection_manager)


def log_info(message):
    logger.get_root_logger().info(message)


def initialize_logging(work_dir):
    logfile = work_dir / f"MGF_Offset_{date_time_tag.get_tag()}.log"
    console_logger.add_filelogger(level.DEBUG, logfile)
    return logfile


def check_lock_file(lock_file):
    if os.path.isfile(lock_file):
        log_info(f"Lock file exists: {lock_file}. Program stopped.")
        return True
    return False


def create_lock_file(lock_file):
    log_info(f"Creating lock file: {lock_file}")
    Path(lock_file).touch()


def check_upload_flag(basename):
    uploaded_flag = Path(work_dir) / UPLOAD_DIR / f"{basename}.uploaded"
    return uploaded_flag.is_file()


def main():
    print("=" * 100)
    print(f"MGF Offset ({VERSION})")

    if len(sys.argv) != 2:
        print("command: python MGF_Offset.py workDir")
        return

    work_dir = Path(sys.argv[1]).absolute()
    log_info(f"workDir: {work_dir}")

    if not work_dir.exists():
        log_info(f"workDir: {work_dir} doesn't exist. Creating the folder")
        work_dir.mkdir(parents=True, exist_ok=True)

    lock_file = work_dir / LOCK_FILE_NAME
    if check_lock_file(lock_file):
        return

    initialize_logging(work_dir)
    create_lock_file(lock_file)

    try:
        delete_logs = True
        delete_logs &= update_mgf_offset(PathFinder().get_dia_mgf_folder(), True)
        delete_logs &= update_mgf_offset(PathFinder().get_dda_mgf_folder(), False)
        delete_logs &= update_mgf_offset(PathFinder().get_hcd_mgf_folder(), True)
        delete_logs &= update_mgf_offset(PathFinder().get_etd_mgf_folder(), True)

        log_info(f"Deleting lock file: {lock_file}")
        lock_file.unlink()  # Remove the lock file

        if delete_logs:
            log_info(f"Deleting log file: {work_dir / f'MGF_Offset_{date_time_tag.get_tag()}.log'}")
            (work_dir / f"MGF_Offset_{date_time_tag.get_tag()}.log").unlink()

    except Exception as e:
        logger.get_root_logger().error(f"MGF Offset failed! Error: {e}")


def update_mgf_offset(mgf_folder, is_true):
    delete_log = True
    executor_pool = executors.new_fixed_thread_pool(8)

    for dir in os.listdir(mgf_folder):
        dir_path = Path(mgf_folder) / dir
        if not dir_path.is_dir():
            continue

        for mgf in os.listdir(dir_path):
            mgf_path = dir_path / mgf
            if not mgf_path.is_file():
                continue

            basename = mgf_path.name
            if not check_upload_flag(basename):
                log_info(f"Upload flag file not found for: {basename}, skipping.")
                continue

            if not is_mgf_processed(basename):
                if database_ms.get_ms_run_id(basename) == -1 or database_ms.get_no_ms2_in_db(basename) == 0:
                    continue

                delete_log = False
                unit = UpdateMgfOffsetUnit(mgf_path, is_true, str(work_dir), db_connection_manager)
                executor_pool.execute(unit)

    executor_pool.shutdown()
    try:
        executor_pool.await_termination(sys.maxsize)
    except KeyboardInterrupt:
        print("interrupted..")
    return delete_log


def is_mgf_processed(basename):
    return any(Path(work_dir).joinpath(f"{basename}.{ext}").is_file() for ext in ["done", "error", "process"])


if __name__ == '__main__':
    main()
