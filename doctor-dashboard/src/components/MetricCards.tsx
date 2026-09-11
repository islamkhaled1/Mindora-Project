import React from 'react';
import { MetricCardItem } from '../types';

interface MetricCardsProps {
  metrics: MetricCardItem[];
}

export default function MetricCards({ metrics }: MetricCardsProps) {
  const getIcon = (type: MetricCardItem['iconName']) => {
    switch (type) {
      case 'user':
        return <i className="fa-regular fa-user metric-icon" aria-hidden="true"></i>;
      case 'users':
        return <i className="fa-solid fa-users metric-icon" aria-hidden="true"></i>;
      case 'alert':
        return <i className="fa-solid fa-triangle-exclamation metric-icon" aria-hidden="true"></i>;
      case 'check':
        return <i className="fa-regular fa-circle-check metric-icon" aria-hidden="true"></i>;
      case 'trending':
        return <i className="fa-solid fa-arrow-trend-up metric-icon" aria-hidden="true"></i>;
      default:
        return null;
    }
  };

  return (
    <section id="metric-cards-section" className="metrics-grid-five">
      {metrics.map((card) => (
        <div
          key={card.id}
          id={`metric-card-${card.id}`}
          className="metric-card-box"
        >
          {/* رأس البطاقة: الأيقونة مع العنوان */}
          <div className="metric-card-header">
            {getIcon(card.iconName)}
            <span className="metric-card-title">{card.title}</span>
          </div>

          {/* الرقم الرئيسي الكبير */}
          <div className="metric-card-value">{card.value}</div>

          {/* كلمة: طفل */}
          <div className="metric-card-unit">{card.unit}</div>
        </div>
      ))}
    </section>
  );
}
