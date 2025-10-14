#!/bin/bash

# Pet Finder Log Monitor Script
# Monitors logs for error messages and implements log rotation

LOG_FILE="/var/log/petfinder.log"
ALERT_FILE="/var/log/petfinder-alerts.log"
ERROR_THRESHOLD=5
TIME_WINDOW=60  # 1 minute in seconds
TEMP_ERROR_FILE="/tmp/petfinder_errors.tmp"

# Create log files if they don't exist
sudo touch "$LOG_FILE" "$ALERT_FILE"
sudo chmod 666 "$LOG_FILE" "$ALERT_FILE"

# Function to log alerts
log_alert() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ALERT: $message" | sudo tee -a "$ALERT_FILE"
    echo "[$timestamp] ALERT: $message"
}

# Function to rotate logs
rotate_logs() {
    local log_file="$1"
    local max_size=10485760  # 10MB in bytes
    
    if [[ -f "$log_file" ]] && [[ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null) -gt $max_size ]]; then
        sudo mv "$log_file" "${log_file}.$(date +%Y%m%d_%H%M%S)"
        sudo touch "$log_file"
        sudo chmod 666 "$log_file"
        log_alert "Log rotated: $log_file"
    fi
}

# Function to monitor errors
monitor_errors() {
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - TIME_WINDOW))
    
    # Extract recent errors (HTTP 500s, ERROR messages)
    if [[ -f "$LOG_FILE" ]]; then
        grep -E "(HTTP/1\.[01]\" 5[0-9][0-9]|ERROR|Error|error)" "$LOG_FILE" | \
        while read -r line; do
            # Extract timestamp from log line (assuming standard format)
            log_time=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)
            if [[ -n "$log_time" ]]; then
                log_timestamp=$(date -d "$log_time" +%s 2>/dev/null || echo $current_time)
                if [[ $log_timestamp -ge $cutoff_time ]]; then
                    echo "$line" >> "$TEMP_ERROR_FILE"
                fi
            else
                # If no timestamp found, assume it's recent
                echo "$line" >> "$TEMP_ERROR_FILE"
            fi
        done
    fi
    
    # Count errors in the time window
    if [[ -f "$TEMP_ERROR_FILE" ]]; then
        error_count=$(wc -l < "$TEMP_ERROR_FILE")
        
        if [[ $error_count -ge $ERROR_THRESHOLD ]]; then
            log_alert "High error rate detected: $error_count errors in last $TIME_WINDOW seconds"
            log_alert "Recent errors:"
            cat "$TEMP_ERROR_FILE" | sudo tee -a "$ALERT_FILE" > /dev/null
        fi
        
        # Clean up temp file
        rm -f "$TEMP_ERROR_FILE"
    fi
}

# Function to simulate log entries for testing
simulate_logs() {
    echo "Simulating log entries for testing..."
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    
    # Simulate normal logs
    echo "[$timestamp] INFO: Pet report submitted successfully" | sudo tee -a "$LOG_FILE"
    echo "[$timestamp] INFO: User authentication successful" | sudo tee -a "$LOG_FILE"
    
    # Simulate error logs
    for i in {1..6}; do
        echo "[$timestamp] ERROR: Database connection failed - attempt $i" | sudo tee -a "$LOG_FILE"
        echo "[$timestamp] ::ffff:127.0.0.1 - - \"POST /v1/users/signup HTTP/1.1\" 500 -" | sudo tee -a "$LOG_FILE"
    done
    
    echo "Simulated logs added to $LOG_FILE"
}

# Main execution
case "${1:-monitor}" in
    "simulate")
        simulate_logs
        ;;
    "rotate")
        rotate_logs "$LOG_FILE"
        ;;
    "monitor")
        echo "Starting Pet Finder log monitoring..."
        echo "Monitoring: $LOG_FILE"
        echo "Error threshold: $ERROR_THRESHOLD errors per $TIME_WINDOW seconds"
        echo "Alerts logged to: $ALERT_FILE"
        echo ""
        
        # Rotate logs if needed
        rotate_logs "$LOG_FILE"
        
        # Monitor for errors
        monitor_errors
        
        echo "Monitoring complete. Check $ALERT_FILE for any alerts."
        ;;
    "continuous")
        echo "Starting continuous monitoring (Ctrl+C to stop)..."
        while true; do
            monitor_errors
            rotate_logs "$LOG_FILE"
            sleep 30  # Check every 30 seconds
        done
        ;;
    *)
        echo "Usage: $0 [monitor|simulate|rotate|continuous]"
        echo "  monitor    - Run single monitoring check (default)"
        echo "  simulate   - Add test log entries"
        echo "  rotate     - Force log rotation"
        echo "  continuous - Run continuous monitoring"
        exit 1
        ;;
esac