#!/usr/bin/env bash
set -euo pipefail

# List of service directories that publish Docker images during mvn install
services=(
  "configserver"
  "eurekaserver"
  "organization-service"
  "licensing-service"
)

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_start="$(date +%s)"
metrics_dir="$(mktemp -d)"
pids=()
services_by_pid=()
start_times=()

cleanup() {
  rm -rf "${metrics_dir}"
}
trap cleanup EXIT

for service in "${services[@]}"; do
  service_dir="${repo_root}/${service}"

  if [[ ! -d "${service_dir}" ]]; then
    echo "Skipping ${service}: directory not found" >&2
    continue
  fi

  echo ">>> Building Docker image for ${service}"

  start_time="$(date +%s)"
  (
    set -o pipefail
    cd "${service_dir}"
    record_result() {
      local exit_code="${1:-$?}"
      local end_time duration
      end_time="$(date +%s)"
      duration=$((end_time - start_time))
      printf '%s %d %d\n' "${service}" "${exit_code}" "${duration}" > "${metrics_dir}/${service}.result"
    }
    trap 'record_result $?' EXIT
    if command -v mvnd >/dev/null 2>&1; then
      cmd=(mvnd clean install)
    elif command -v mvn >/dev/null 2>&1; then
      cmd=(mvn clean install)
    elif [[ -x "./mvnw" ]]; then
      cmd=(./mvnw clean install)
    else
      echo "[${service}] No Maven command (mvnd, mvn, mvnw) available" >&2
      exit 1
    fi
    echo "[${service}] Running command: ${cmd[*]}"
    "${cmd[@]}" 2>&1 | while IFS= read -r line; do
      echo "[${service}] $line"
    done
  ) &
  pids+=($!)
  services_by_pid+=("$service")
  start_times+=("${start_time}")
done

# Wait for all background jobs to finish and check their exit codes
exit_code=0
declare -a failed_services=()
for i in "${!pids[@]}"; do
  pid="${pids[$i]}"
  service="${services_by_pid[$i]}"
  start_time="${start_times[$i]}"
  if wait "${pid}"; then
    status=0
  else
    status=$?
  fi
  result_file="${metrics_dir}/${service}.result"
  recorded_service=""
  recorded_status=""
  recorded_duration=""
  if [[ -f "${result_file}" ]]; then
    if read -r recorded_service recorded_status recorded_duration < "${result_file}"; then
      :
    fi
    rm -f "${result_file}"
  fi
  if [[ -n "${recorded_status}" ]]; then
    status="${recorded_status}"
  fi
  if [[ -n "${recorded_duration}" ]]; then
    duration="${recorded_duration}"
  else
    end_time="$(date +%s)"
    duration=$((end_time - start_time))
  fi
  if [[ "${status}" -ne 0 ]]; then
    exit_code=1
    failed_services+=("${service}")
    echo "[${service}] Failed after ${duration}s" >&2
  else
    echo "[${service}] Completed in ${duration}s"
  fi
done

total_duration=$(( $(date +%s) - script_start ))

if [[ "${exit_code}" -ne 0 ]]; then
  echo ">>> Build failed for the following services: ${failed_services[*]}" >&2
  echo ">>> Total elapsed time: ${total_duration}s" >&2
  exit "${exit_code}"
fi

echo ">>> All Docker image builds complete in ${total_duration}s"
