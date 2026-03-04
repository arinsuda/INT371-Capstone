package criminalcheck

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"strconv"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) VerifyIdentity(c fiber.Ctx) error {
	technicianID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, technicianID); err != nil {
		return appErrors.HandleError(c, err)
	}

	fileHeader, err := c.FormFile("file")
	if err != nil {
		return appErrors.BadRequest(c, "กรุณาแนบรูปบัตรประชาชน (field: file)")
	}

	file, err := fileHeader.Open()
	if err != nil {
		return appErrors.BadRequest(c, "ไม่สามารถเปิดไฟล์ได้")
	}
	defer file.Close()

	var buf bytes.Buffer
	if _, err := io.Copy(&buf, file); err != nil {
		return appErrors.InternalError(c, "ไม่สามารถอ่านไฟล์ได้", err)
	}

	resp, err := h.service.VerifyIdentity(c.Context(), technicianID, buf.Bytes(), fileHeader.Filename)
	if err != nil {
		return appErrors.InternalError(c, "failed to verify identity", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetStats(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	stats, err := h.service.GetStats(c.Context())
	if err != nil {
		return appErrors.InternalError(c, "failed to get stats", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": stats})
}

func (h *Handler) ListLogs(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	filter := ListLogsFilter{
		Status:     c.Query("status"),
		NationalID: c.Query("national_id"),
		TechName:   c.Query("tech_name"),
		DateFrom:   c.Query("date_from"),
		DateTo:     c.Query("date_to"),
	}

	if p, err := strconv.Atoi(c.Query("page", "1")); err == nil {
		filter.Page = p
	}
	if ps, err := strconv.Atoi(c.Query("page_size", "20")); err == nil {
		filter.PageSize = ps
	}

	resp, err := h.service.ListLogs(c.Context(), filter)
	if err != nil {
		return appErrors.InternalError(c, "failed to list logs", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetLogsByTechnician(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	technicianID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	logs, err := h.service.GetLogsByTechnician(c.Context(), technicianID)
	if err != nil {
		return appErrors.InternalError(c, "failed to get logs", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": logs})
}

func (h *Handler) UpdateLogStatus(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	logID, err := utils.ParseUintParam(c, "logID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid log id")
	}

	var req UpdateLogStatusRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	adminID, _ := middleware.GetUserID(c)

	resp, err := h.service.UpdateLogStatus(c.Context(), adminID, logID, req)
	if err != nil {
		if errors.Is(err, ErrLogNotFound) {
			return appErrors.NotFound(c, "verification log not found")
		}
		return appErrors.InternalError(c, "failed to update log status", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) OverrideIsVerified(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	technicianID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	var req OverrideIsVerifiedRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	adminID, _ := middleware.GetUserID(c)

	if err := h.service.OverrideIsVerified(c.Context(), adminID, technicianID, req); err != nil {
		if errors.Is(err, ErrTechNotFound) {
			return appErrors.NotFound(c, "technician not found")
		}
		return appErrors.InternalError(c, "failed to override is_verified", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": fmt.Sprintf("อัปเดต is_verified เป็น %v สำเร็จ", req.IsVerified),
	})
}

func (h *Handler) ListCriminalRecords(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	page, _ := strconv.Atoi(c.Query("page", "1"))
	pageSize, _ := strconv.Atoi(c.Query("page_size", "20"))
	status := c.Query("status")

	records, total, err := h.service.ListCriminalRecords(c.Context(), page, pageSize, status)
	if err != nil {
		return appErrors.InternalError(c, "failed to list criminal records", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"records":   records,
			"total":     total,
			"page":      page,
			"page_size": pageSize,
		},
	})
}

func (h *Handler) GetCriminalRecord(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	id, err := utils.ParseUintParam(c, "recordID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid record id")
	}

	record, err := h.service.GetCriminalRecord(c.Context(), id)
	if err != nil {
		if errors.Is(err, ErrCriminalRecordNotFound) {
			return appErrors.NotFound(c, "criminal record not found")
		}
		return appErrors.InternalError(c, "failed to get criminal record", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": record})
}

func (h *Handler) CreateCriminalRecord(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	var req CreateCriminalRecordRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	record, err := h.service.CreateCriminalRecord(c.Context(), req)
	if err != nil {
		if errors.Is(err, ErrNationalIDDuplicate) {
			return appErrors.Conflict(c, "เลขบัตรประชาชนนี้มีในระบบแล้ว")
		}
		return appErrors.InternalError(c, "failed to create criminal record", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": record})
}

func (h *Handler) UpdateCriminalRecord(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	id, err := utils.ParseUintParam(c, "recordID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid record id")
	}

	var req UpdateCriminalRecordRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	record, err := h.service.UpdateCriminalRecord(c.Context(), id, req)
	if err != nil {
		if errors.Is(err, ErrCriminalRecordNotFound) {
			return appErrors.NotFound(c, "criminal record not found")
		}
		return appErrors.InternalError(c, "failed to update criminal record", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": record})
}

func (h *Handler) DeleteCriminalRecord(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	id, err := utils.ParseUintParam(c, "recordID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid record id")
	}

	if err := h.service.DeleteCriminalRecord(c.Context(), id); err != nil {
		if errors.Is(err, ErrCriminalRecordNotFound) {
			return appErrors.NotFound(c, "criminal record not found")
		}
		return appErrors.InternalError(c, "failed to delete criminal record", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "ลบข้อมูลสำเร็จ"})
}
