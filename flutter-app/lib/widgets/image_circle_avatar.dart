import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/core/utils/child_avatar_helper.dart';

class ImageCircleAvatar extends StatelessWidget {
  const ImageCircleAvatar({
    super.key,
    this.image,
    this.avatarUrl,
    this.gender,
    this.radius,
  });

  final String? image;
  final String? avatarUrl;
  final dynamic gender;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? 30.r;
    final resolvedSource = image ??
        ChildAvatarHelper.resolve(
          gender: gender,
          avatarUrl: avatarUrl,
        );

    final isNetwork = ChildAvatarHelper.isNetworkUrl(resolvedSource);

    return CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: effectiveRadius,
      child: ClipOval(
        child: SizedBox(
          width: effectiveRadius * 2,
          height: effectiveRadius * 2,
          child: isNetwork
              ? Image.network(
                  resolvedSource,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    ChildAvatarHelper.resolve(gender: gender),
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  resolvedSource,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}
