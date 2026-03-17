import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/book_info.dart';
import 'custom_card.dart';

class HistoryCard extends StatelessWidget {
  final BookInfo book;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const HistoryCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (book.status) {
      case ConversionStatus.completed:
        statusColor = Colors.green;
        statusText = '转换完成';
        statusIcon = Icons.check_circle;
        break;
      case ConversionStatus.converting:
        statusColor = Colors.blue;
        statusText = '转换中';
        statusIcon = Icons.hourglass_empty;
        break;
      case ConversionStatus.failed:
        statusColor = Colors.red;
        statusText = '转换失败';
        statusIcon = Icons.error;
        break;
      case ConversionStatus.pending:
      default:
        statusColor = Colors.grey;
        statusText = '等待转换';
        statusIcon = Icons.schedule;
        break;
    }

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面预览
          if (book.coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                book.coverImage!,
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.book,
                      color: theme.primaryColor,
                      size: 30,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: theme.primaryColor,
                size: 30,
              ),
            ),
          const SizedBox(width: 12),
          // 书籍信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (book.author.isNotEmpty)
                  Text(
                    book.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  '${book.chapters.length} 章',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(book.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 操作按钮
          Column(
            children: [
              if (book.status == ConversionStatus.completed)
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: onShare,
                  tooltip: '分享',
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: onDelete,
                tooltip: '删除',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
