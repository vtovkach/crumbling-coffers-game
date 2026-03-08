#ifndef _LOG_SYSTEM_H
#define _LOG_SYSTEM_H

#include <stdio.h>

/* 
 * @purpose:
 * Writes a general informational message to the provided log file.
 * Used for normal runtime events such as server startup, connection
 * events, state changes, or other non-error status messages.
 *
 * @param log_file  Pointer to the log file where the message is written.
 * @param msg       Null-terminated message string to record in the log.
 */
void log_message(FILE *const log_file, const char *msg);

/*
 * @purpose:
 * Writes an error message to the log file together with the associated
 * errno value. Intended for reporting failures of system calls or other
 * operations where errno provides additional diagnostic information.
 *
 * If errno_code is 0, it indicates that no errno value is associated
 * with the error and only the provided message should be logged.
 *
 * @param log_file   Pointer to the log file where the error is recorded.
 * @param msg        Description of the error or failed operation.
 * @param errno_code errno value captured at the moment the error occurred
 *                   (0 means no errno is associated with the error).
 */
void log_error(FILE *const log_file, const char *msg, int errno_code);

/*
 * @purpose:
 * Logs an error related to a specific file descriptor (typically a network
 * connection). The log entry includes a descriptive error message, the file
 * descriptor involved, and optionally an errno value if the failure was
 * caused by a system call.
 *
 * If errno_code is 0, it indicates that no errno value is associated with
 * the error and only the provided message and file descriptor are logged.
 *
 * @param log_file   Pointer to the log file where the error is recorded.
 * @param err_msg    Description of the error or failed operation.
 * @param conn_fd    File descriptor associated with the error.
 * @param errno_code errno value captured at the moment the error occurred
 *                   (0 means no errno is associated with the error).
 */
void log_error_fd(FILE *const log_file, const char *err_msg, int conn_fd, int errno_code);

/*
 * @purpose:
 * Debug utility used during development to display network buffer contents
 * in the log. The function copies the received buffer into a temporary
 * printable string and fills unused space with '$' characters so the full
 * buffer length can be visually inspected.
 *
 *
 * @param log_file  Log file where the message will be written.
 * @param buf       Buffer received from the network.
 * @param buf_size  Size of the network buffer.
 */
void log_net_data(FILE *const log_file, const char *const buf, size_t buf_size);

#endif