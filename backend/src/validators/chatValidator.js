const { body, validationResult } = require('express-validator');

const validateMessage = [
  body('message')
    .trim()
    .notEmpty()
    .withMessage('Message content is required')
    .isLength({ max: 5000 })
    .withMessage('Message cannot exceed 5000 characters'),
  body('receiverId')
    .optional()
    .isMongoId()
    .withMessage('Invalid receiver ID'),
  body('receiver')
    .optional()
    .isMongoId()
    .withMessage('Invalid receiver ID'),
  body().custom((_, { req }) => {
    if (!req.body.receiverId && !req.body.receiver) {
      throw new Error('Receiver ID is required');
    }
    return true;
  }),
  body('messageType')
    .optional()
    .isIn(['text', 'image', 'file', 'emoji'])
    .withMessage('Invalid message type'),
];

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const mapped = errors.array().map((err) => ({
      field: err.path,
      message: err.msg,
    }));
    return res.status(400).json({
      success: false,
      message: mapped[0]?.message || 'Validation failed',
      errors: mapped,
    });
  }
  next();
};

module.exports = { validateMessage, validate };