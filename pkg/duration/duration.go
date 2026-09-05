package duration

import (
	"fmt"
	"strconv"
	"strings"
	"time"
)

func ParseDayDuration(durationStr string) (time.Duration, error) {
	durationStr = strings.TrimSpace(durationStr)

	if strings.HasSuffix(durationStr, "d") {
		daysStr := strings.TrimSuffix(durationStr, "d")
		days, err := strconv.Atoi(daysStr)
		if err != nil {
			return 0, fmt.Errorf("format hari tidak valid: %s", durationStr)
		}

		durationStr = fmt.Sprintf("%dh", days*24)
	}

	// Gunakan fungsi bawaan Go untuk mem-parse (sekarang sudah jadi format 'h')
	return time.ParseDuration(durationStr)
}
